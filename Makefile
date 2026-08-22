.PHONY: help up down api-shell migrate seed test-rules test-rules-py test-api test-forecasting test-flutter analyze-flutter build-windows

help:
	@echo "make up                 - docker compose up (postgres, redis, api)"
	@echo "make down               - docker compose down"
	@echo "make migrate            - alembic upgrade head (run inside services/api with a venv)"
	@echo "make seed               - run scripts/seed_data.py"
	@echo "make test-rules         - dart test on packages/election_rules (verified in this repo)"
	@echo "make test-rules-py      - pytest on packages/election_rules_py (requires local Python)"
	@echo "make test-api           - pytest on services/api"
	@echo "make test-forecasting   - pytest on services/forecasting"
	@echo "make test-flutter       - flutter test on apps/flutter_client (verified in this repo)"
	@echo "make analyze-flutter    - flutter analyze on apps/flutter_client (verified in this repo)"
	@echo "make build-windows      - flutter build windows --release"

up:
	docker compose up -d

down:
	docker compose down

migrate:
	cd services/api && alembic upgrade head

seed:
	python scripts/seed_data.py

test-rules:
	cd packages/election_rules && dart pub get && dart test

test-rules-py:
	cd packages/election_rules_py && pip install -e .[dev] && pytest

test-api:
	cd services/api && pip install -r requirements.txt && pytest

test-forecasting:
	cd services/forecasting && pip install -r requirements.txt && pip install pytest && pytest

test-flutter:
	cd apps/flutter_client && flutter test

analyze-flutter:
	cd apps/flutter_client && flutter analyze

build-windows:
	cd apps/flutter_client && flutter build windows --release
