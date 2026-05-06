COMPOSE = docker compose -f deploy/docker-compose.yml --env-file .env
COLLECTOR_HEALTH = http://localhost:13133   # health_check extension (added below)
PROMETHEUS_URL   = http://localhost:9090
GRAFANA_URL      = http://localhost:3000

.PHONY: help up down restart logs status verify clean

help:
	@echo ""
	@echo "  Agent Sentinel — command reference"
	@echo ""
	@echo "  make up        Start full monitoring stack"
	@echo "  make down      Stop and remove containers (data volumes preserved)"
	@echo "  make restart   Restart all services"
	@echo "  make logs      Tail logs for all services"
	@echo "  make status    Show container status"
	@echo "  make verify    Verify OTel Collector is reachable and accepting data"
	@echo "  make clean     Stop containers AND delete all volumes (destructive!)"
	@echo ""

up: _check_env
	$(COMPOSE) up -d
	@echo ""
	@echo "  Stack is starting. Run 'make verify' in ~10s to confirm health."
	@echo "  Grafana:    $(GRAFANA_URL)  (admin / $${GRAFANA_ADMIN_PASSWORD:-sentinel})"
	@echo "  Prometheus: $(PROMETHEUS_URL)"
	@echo ""

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

logs:
	$(COMPOSE) logs -f

status:
	$(COMPOSE) ps

verify:
	@echo "--- Checking OTel Collector (OTLP HTTP endpoint) ---"
	@curl -sf -o /dev/null -w "  OTLP HTTP 4318: %{http_code}\n" \
		http://localhost:4318/v1/metrics \
		-H "Content-Type: application/json" \
		-d '{"resourceMetrics":[]}' \
		|| echo "  OTLP HTTP 4318: UNREACHABLE"

	@echo "--- Checking Prometheus ---"
	@curl -sf -o /dev/null -w "  Prometheus 9090: %{http_code}\n" \
		$(PROMETHEUS_URL)/-/healthy \
		|| echo "  Prometheus 9090: UNREACHABLE"

	@echo "--- Checking Grafana ---"
	@curl -sf -o /dev/null -w "  Grafana 3000:    %{http_code}\n" \
		$(GRAFANA_URL)/api/health \
		|| echo "  Grafana 3000:    UNREACHABLE"

	@echo "--- Collector self-metrics (spot-check) ---"
	@curl -sf http://localhost:8889/metrics | grep -m 3 "^agent_sentinel" \
		|| echo "  No agent_sentinel metrics yet — send some test data first."

	@echo ""
	@echo "Send a test metric:"
	@echo '  make test-send'

test-send:
	@echo "Sending synthetic metric to OTLP HTTP..."
	@curl -sf http://localhost:4318/v1/metrics \
		-H "Content-Type: application/json" \
		-d '{ \
			"resourceMetrics": [{ \
				"resource": { \
					"attributes": [{"key":"service.name","value":{"stringValue":"test-agent"}}] \
				}, \
				"scopeMetrics": [{ \
					"metrics": [{ \
						"name": "agent_context_battery_percent", \
						"gauge": { \
							"dataPoints": [{ \
								"asDouble": 75.0, \
								"timeUnixNano": "'$$(date +%s%N)'" \
							}] \
						} \
					}] \
				}] \
			}] \
		}' && echo "  OK — check Prometheus at $(PROMETHEUS_URL)/graph?g0.expr=agent_sentinel_agent_context_battery_percent"

clean:
	@echo "WARNING: This will delete all Prometheus and Grafana data."
	@read -p "Continue? [y/N] " ans && [ "$$ans" = "y" ]
	$(COMPOSE) down -v

_check_env:
	@if [ ! -f .env ]; then \
		echo "No .env file found. Copying from .env.example..."; \
		cp .env.example .env; \
		echo "Edit .env if needed, then re-run 'make up'."; \
	fi
