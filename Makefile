# ────────────────────────────────────────────────
# Flarum Makefile
# Production: docker-compose.prod.yml
# Development: docker-compose.dev.yml
# ────────────────────────────────────────────────

COMPOSE_FILE := docker-compose.prod.yml
DEV_COMPOSE_FILE := docker-compose.dev.yml
PROJECT_NAME := flarum-prod
DEV_PROJECT_NAME := flarum-dev

DC := docker compose -p $(PROJECT_NAME) -f $(COMPOSE_FILE)
DC_DEV := docker compose -p $(DEV_PROJECT_NAME) -f $(DEV_COMPOSE_FILE)

.PHONY: help build rebuild pull up down restart logs ps shell pull update cache-clear deploy clean \
        migrate dev-build dev-up dev-down dev-restart dev-logs dev-ps dev-shell dev-rebuild dev-clean \
        dev-migrate dev-cache-clear dev-deploy dev-logs-worker

##@ Default

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

##@ Production

build: ## Build the flarum production image
	$(DC) build

rebuild: ## Rebuild the image without cache, then restart
	$(DC) build --no-cache
	$(DC) up -d

pull: ## Pull latest base images (db, cache)
	$(DC) pull db cache

up: ## Start all services in detached mode
	$(DC) up -d

down: ## Stop and remove all containers (volumes are preserved)
	$(DC) down

restart: ## Restart all services
	$(DC) restart

logs: ## Tail logs from all services (-f)
	$(DC) logs -f

ps: ## Show service status
	$(DC) ps

shell: ## Open a bash shell inside the flarum container
	$(DC) exec flarum bash

update: ## Update flarum dependencies inside the running container
	$(DC) exec flarum composer update

cache-clear: ## Clear flarum cache (storage/cache + storage/views)
	$(DC) exec flarum rm -rf storage/cache/* storage/views/*

deploy: build ## Full production deploy: build → up → migrate → cache:clear
	$(DC) up -d
	$(DC) exec flarum sh -c 'i=0; until php flarum migrate 2>/dev/null; do i=$$((i+1)); if [ $$i -ge 10 ]; then php flarum migrate; exit 1; fi; sleep 3; done'
	$(DC) exec flarum php flarum cache:clear

migrate: ## Apply pending DB migrations (php flarum migrate)
	$(DC) exec flarum php flarum migrate

clean: down ## Full teardown: stop containers + remove built image
	docker rmi $$(docker images -q '$(PROJECT_NAME)*' 2>/dev/null || true) 2>/dev/null || true

##@ Development

dev-build: ## Build the flarum dev image
	$(DC_DEV) build

dev-rebuild: ## Rebuild the dev image without cache, then restart
	$(DC_DEV) build --no-cache
	$(DC_DEV) up -d

dev-up: ## Start all dev services in detached mode
	$(DC_DEV) up -d

dev-down: ## Stop and remove all dev containers
	$(DC_DEV) down

dev-restart: ## Restart all dev services
	$(DC_DEV) restart

dev-logs: ## Tail logs from all dev services (-f)
	$(DC_DEV) logs -f

dev-ps: ## Show dev service status
	$(DC_DEV) ps

dev-shell: ## Open a bash shell inside the dev flarum container
	$(DC_DEV) exec flarum bash

dev-migrate: ## Apply pending DB migrations in the dev container
	$(DC_DEV) exec flarum php flarum migrate

dev-cache-clear: ## Clear flarum cache + republish assets (php flarum cache:clear)
	$(DC_DEV) exec flarum php flarum cache:clear

dev-deploy: dev-build dev-up ## Full dev deploy: build → up → migrate → cache:clear
	$(DC_DEV) exec flarum sh -c 'i=0; until php flarum migrate 2>/dev/null; do i=$$((i+1)); if [ $$i -ge 10 ]; then php flarum migrate; exit 1; fi; sleep 3; done'
	$(DC_DEV) exec flarum php flarum cache:clear

dev-logs-worker: ## Tail translator-worker logs (-f)
	$(DC_DEV) logs -f translator-worker

dev-clean: dev-down ## Full teardown: stop dev containers + remove built image
	docker rmi $$(docker images -q '$(DEV_PROJECT_NAME)*' 2>/dev/null || true) 2>/dev/null || true