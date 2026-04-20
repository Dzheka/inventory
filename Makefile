.PHONY: help up down logs migrate admin shell test lint

DOCKER=docker compose
BACKEND=docker compose exec backend

# ── Top-level ──────────────────────────────────────────────────────────────────

help:
	@echo ""
	@echo "  make up           Start all services (postgres, redis, minio, backend, celery)"
	@echo "  make down         Stop and remove containers"
	@echo "  make logs         Follow backend logs"
	@echo "  make migrate      Run Alembic migrations inside backend container"
	@echo "  make admin        Create the first admin user (USERNAME= PASSWORD= FULLNAME=)"
	@echo "  make shell        Open a bash shell inside backend container"
	@echo "  make test         Run backend tests"
	@echo "  make lint         Run ruff linter on backend"
	@echo "  make mobile-gen   Run Flutter build_runner (generate .g.dart files)"
	@echo ""

# ── Infrastructure ─────────────────────────────────────────────────────────────

up:
	@cp -n .env.example .env 2>/dev/null || true
	$(DOCKER) up -d --build

down:
	$(DOCKER) down

logs:
	$(DOCKER) logs -f backend

# ── Database ───────────────────────────────────────────────────────────────────

migrate:
	$(BACKEND) alembic upgrade head

migrate-down:
	$(BACKEND) alembic downgrade -1

migrate-history:
	$(BACKEND) alembic history --verbose

# ── Admin user ─────────────────────────────────────────────────────────────────

admin:
	$(BACKEND) python -m scripts.create_admin \
		--username $${USERNAME:-admin} \
		--password $${PASSWORD:-changeme} \
		--full-name "$${FULLNAME:-Administrator}"

# ── Development ────────────────────────────────────────────────────────────────

shell:
	$(BACKEND) bash

test:
	$(BACKEND) pytest -v

lint:
	$(BACKEND) ruff check app/

# ── Mobile ─────────────────────────────────────────────────────────────────────

mobile-gen:
	cd mobile && dart run build_runner build --delete-conflicting-outputs

mobile-watch:
	cd mobile && dart run build_runner watch --delete-conflicting-outputs
