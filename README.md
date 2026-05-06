# Agent Sentinel

Local observability base for AI agents. Captures OTel telemetry → Prometheus → Grafana.

## Quick Start

```bash
make up       # starts OTel Collector + Prometheus + Grafana
make verify   # confirms all endpoints are healthy
make test-send # sends a synthetic metric to verify the pipeline end-to-end
```

- **Grafana:** http://localhost:3000 (admin / sentinel)
- **Prometheus:** http://localhost:9090

## Instrument your agent

```bash
cp .env.example /path/to/your-agent/.env
# edit OTEL_SERVICE_NAME, AGENT_PROJECT, etc.
```

See `internal/metrics/definitions.md` for metric schemas and instrumentation snippets.

## Project structure

```
agent-sentinel/
├── deploy/
│   ├── docker-compose.yml          # OTel Collector + Prometheus + Grafana
│   ├── otel-collector-config.yml   # Collector pipelines
│   ├── prometheus.yml              # Scrape config
│   └── grafana/provisioning/       # Auto-provisioned datasource
├── internal/metrics/
│   └── definitions.md              # Metric schemas + formulas
├── dashboards/                     # Grafana dashboard JSON (auto-loaded)
│   └── README.md                   # Versioned dashboard roadmap
├── agents/example/                 # Instrumentation reference
├── .env.example                    # All OTel env vars documented
└── Makefile                        # make up / verify / test-send / clean
```
