# Example Agent Instrumentation

Drop instrumented agent code here. The pattern for any agent project:

1. Copy `.env.example` → `.env` in *your agent's project root*
2. Set `OTEL_SERVICE_NAME`, `OTEL_SERVICE_NAMESPACE`, `AGENT_PROJECT`
3. Point `OTEL_EXPORTER_OTLP_ENDPOINT` at the running Collector (`http://localhost:4317`)
4. Emit the metrics defined in `internal/metrics/definitions.md`
5. Open Grafana at http://localhost:3000 — your agent appears automatically

Multiple agents can push to the same Collector simultaneously.
Filter by `agent_name` or `service_namespace` labels in Grafana.
