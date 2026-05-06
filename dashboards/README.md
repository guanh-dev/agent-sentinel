# Dashboards Roadmap

Place Grafana dashboard JSON exports here. Grafana auto-loads them via the provisioning provider.

## v1 — Baseline vitals
- Context Battery gauge per agent
- LLM request rate and latency (p50/p95/p99)
- Tool call success/error rate
- Token consumption over time

## v2 — Desperation Index
- Desperation Index gauge (0–1), color threshold at 0.7
- Action repetition heatmap
- Error rate sparklines per tool
- Grafana alert: desperation_index > 0.7 for 2 minutes

## v3 — Trace X-Ray (requires Tempo)
- Add Grafana Tempo to docker-compose.yml
- Trace waterfall: which tool calls are slowest
- Span error annotation overlay on timeline
- Exemplar links from Prometheus metrics → Tempo traces
