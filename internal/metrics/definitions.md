# Agent Sentinel — Metric Definitions

All metrics use the prefix `agent_sentinel_` after Prometheus namespace normalization.

---

## 1. Desperation Index (绝望指数)

**Metric name:** `agent_desperation_index` (Gauge, 0.0–1.0)

**Purpose:** Signals when an agent is stuck in a failure loop — high error rate combined with action repetition.

**Formula:**
```
desperation_index = clamp(
    (error_rate_weight * normalized_error_rate) +
    (repetition_weight * action_repetition_ratio),
    0.0, 1.0
)

where:
  normalized_error_rate    = errors_last_5min / max_expected_errors_per_5min
  action_repetition_ratio  = repeated_tool_calls_last_10 / 10
  error_rate_weight        = 0.6
  repetition_weight        = 0.4
```

**Input metrics required from agent:**
| Metric | Type | Description |
|--------|------|-------------|
| `agent_tool_errors_total` | Counter | Incremented on each tool call error |
| `agent_tool_calls_total` | Counter | Total tool invocations, label `tool_name` |
| `agent_repeated_actions_total` | Counter | Detected identical consecutive actions |

**Grafana alert threshold:** > 0.7 → panel turns red.

---

## 2. Confidence Score (置信度)

**Metric name:** `agent_confidence_score` (Gauge, 0.0–1.0)

**Purpose:** Agent's self-reported certainty. Emit this metric when the agent introspects its own uncertainty (e.g., hedging phrases detected, low log-probability outputs).

**Formula (agent-side):**
```
confidence_score = 1.0 - uncertainty_signal
```

Where `uncertainty_signal` can be derived from:
- Log-probability entropy of the last response tokens (if accessible via API)
- Keyword detection: "I'm not sure", "maybe", "I think" → subtract 0.1 each

**Input metrics required from agent:**
| Metric | Type | Description |
|--------|------|-------------|
| `agent_confidence_score` | Gauge | Directly emitted by agent, range 0–1 |

---

## 3. Context Battery (上下文电量)

**Metric name:** `agent_context_battery_percent` (Gauge, 0.0–100.0)

**Purpose:** Shows how much context window capacity remains. Critical for preventing silent truncation failures.

**Formula:**
```
context_battery_percent = (1.0 - tokens_used / context_window_max) * 100
```

**Input metrics required from agent:**
| Metric | Type | Description |
|--------|------|-------------|
| `agent_tokens_used_total` | Counter | Cumulative tokens consumed in session |
| `agent_context_window_max` | Gauge | Set once at agent startup from `AGENT_CONTEXT_WINDOW` env |

**Grafana alert thresholds:**
- < 30% → yellow warning
- < 10% → red critical

---

## 4. Standard Performance Metrics

These are expected from every instrumented agent:

| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| `agent_task_duration_seconds` | Histogram | `task_type` | End-to-end task latency |
| `agent_llm_request_duration_seconds` | Histogram | `model` | Per-LLM-call latency |
| `agent_llm_requests_total` | Counter | `model`, `status` | Total LLM calls |
| `agent_tool_calls_total` | Counter | `tool_name`, `status` | Tool invocations |
| `agent_tool_errors_total` | Counter | `tool_name`, `error_type` | Tool failures |
| `agent_session_tokens_total` | Counter | `direction` (in/out) | Token accounting |

---

## Instrumentation Quick-Start

### Python (opentelemetry-sdk)
```python
from opentelemetry import metrics
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
import os

exporter = OTLPMetricExporter(endpoint=os.environ["OTEL_EXPORTER_OTLP_ENDPOINT"])
reader = PeriodicExportingMetricReader(exporter, export_interval_millis=10_000)
provider = MeterProvider(metric_readers=[reader])
metrics.set_meter_provider(provider)

meter = metrics.get_meter(os.environ["OTEL_SERVICE_NAME"])

# Example: emit context battery
context_battery = meter.create_gauge("agent_context_battery_percent")
context_battery.set(85.0, {"agent.project": os.environ.get("AGENT_PROJECT", "default")})
```

### Node.js / TypeScript
```typescript
import { metrics } from "@opentelemetry/api";
// Configure provider via env vars — OTEL_EXPORTER_OTLP_ENDPOINT auto-picked up
const meter = metrics.getMeter(process.env.OTEL_SERVICE_NAME!);
const desperationIndex = meter.createObservableGauge("agent_desperation_index");
desperationIndex.addCallback((obs) => obs.observe(computeDesperation()));
```
