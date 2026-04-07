.PHONY: install dev build docker-build docker-up docker-down docker-logs help zip clean

default: help

install: ## Install frontend dependencies
	cd web/frontend && npm install

dev: ## Start backend + frontend dev servers
	cd web && uvicorn backend.app:app --host 127.0.0.1 --port 8084 --reload &
	cd web/frontend && npm run dev

build: ## Build frontend for production
	cd web/frontend && npm run build

docker-build: ## Build Docker image
	docker compose build

docker-up: ## Start Docker container
	docker compose up -d

docker-down: ## Stop Docker container
	docker compose down

docker-logs: ## Tail container logs
	docker compose logs -f

zip: ## Package sources for submission
	zip -r PROJ.24.zip *.pdf sources/

clean: ## Clean build artifacts
	rm -rf web/frontend/dist web/frontend/node_modules *.zip

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'
