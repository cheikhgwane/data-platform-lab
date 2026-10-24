SHELL := /bin/bash
.DEFAULT_GOAL := help

help: ## List targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

.env:
	cp .env.example .env

up: .env ## Start primary + 2 replicas and wait until healthy
	docker compose up -d --wait
	@./scripts/check_replication.sh

down: ## Stop everything and delete the data volumes
	docker compose down -v

status: ## Replication status from the primary
	@./scripts/check_replication.sh

smoke: ## Assert both replicas are streaming (used by CI)
	@./scripts/assert_streaming.sh

load: ## pgbench write load on the primary (DURATION=60 CLIENTS=8)
	@./scripts/load.sh

lag: ## Sample replication lag to results/*.csv (DURATION=60)
	@./scripts/lag_watch.sh

sync-on: ## Make pg_replica_1 synchronous
	@./scripts/sync_mode.sh on

sync-off: ## Back to asynchronous replication
	@./scripts/sync_mode.sh off

failover: ## Kill the primary, promote replica 1, repoint replica 2
	@./scripts/failover.sh

rejoin: ## Rewind the old primary and rejoin it as a replica
	@./scripts/rejoin_old_primary.sh

psql: ## psql on the primary
	docker exec -it pg-primary psql -U postgres

lint: ## shellcheck + compose validation
	shellcheck -x scripts/*.sh primary/*.sh replica/*.sh
	docker compose config -q

.PHONY: help up down status smoke load lag sync-on sync-off failover rejoin psql lint
