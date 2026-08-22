# Deployment

## Local development

See README "Getting started" for exact commands. Summary:
`docker compose up` brings up Postgres, Redis, and the API; `flutter run`
runs the client against bundled demo data or a configured API base URL.

## Docker

- `services/api/Dockerfile` — multi-stage-free, single Python 3.12-slim
  image; installs `packages/election_rules_py` and `services/forecasting`
  as editable local dependencies before the API's own requirements.
- `docker-compose.yml` (repo root) — `postgres:16-alpine`,
  `redis:7-alpine`, and the `api` service, with `.env` loaded via
  `env_file`. A production compose file should drop the bind-mounted
  source volumes used here for local dev and add a `worker` service
  running the ingestion/forecast scheduler (not included in this build's
  compose file — see README "What's not built yet").

## Database

Run migrations with `alembic upgrade head` from `services/api/` — no
migration has been generated yet in this repository (no Python runtime in
the build sandbox); generate the initial one in a real environment:
`alembic revision --autogenerate -m "initial schema"`.

## Backups

Not automated in this build. For production:
- `pg_dump`/point-in-time recovery on the Postgres volume.
- `ForecastRun` rows are immutable by design (section 39) — a backup
  strategy only needs to protect against volume loss, not
  application-level overwrites of forecast history.

## Flutter release builds

```
# Windows
flutter build windows --release

# Android (requires a configured signing key — see Flutter's official
# "Build and release an Android app" guide before shipping)
flutter build appbundle --release
```

## 24/7 ingestion & forecasting

**No server budget?** See `docs/FREE_TIER_DEPLOYMENT.md` — the same
underlying logic (`services/ingestion/ingestion/jobs.py`) runs from a
free GitHub Actions scheduled workflow instead of a paid Celery worker.
This section covers the Celery-on-a-real-server path.

The platform only becomes "dynamic" — continuously pulling news, detecting
coalition signals, and re-running the forecast — once
`services/ingestion/ingestion/celery_app.py` is deployed as a **long-running
process**. Nothing runs on a schedule just because the code exists in the
repository; a session like the one that wrote this code is not a server
and cannot leave a background job running after it ends.

```bash
cd services/ingestion
pip install -r requirements.txt   # installs services/api + forecasting as
                                   # editable deps so tasks.py can import
                                   # app.db / app.models / the forecast runner

# One process running both the worker and the beat scheduler (fine for a
# single small deployment; split into two processes for production):
celery -A ingestion.celery_app worker --beat -l info
```

What the schedule does (see `services/ingestion/ingestion/celery_app.py` /
`tasks.py`):

| Task | Cadence (`.env`) | What it does |
|---|---|---|
| `ingest_all_sources_task` | `INGESTION_POLL_INTERVAL_MINUTES` (default 15) | Fetches active RSS `NewsSource` rows, dedupes, stores permitted metadata + snippet only, runs the configured `PoliticalNlpProvider`, flags high-impact/low-confidence extractions for review. |
| `discover_news_via_ai_task` | `INGESTION_POLL_INTERVAL_MINUTES` | No-ops unless `OPENAI_API_KEY` is set — otherwise searches the web for news via OpenAI's `web_search` tool (`sources/openai_search_adapter.py`), no per-outlet feed URL needed, and runs it through the same dedupe/extraction pipeline as RSS. |
| `discover_polls_via_ai_task` | `FORECAST_RECOMPUTE_INTERVAL_MINUTES` | No-ops unless `OPENAI_API_KEY` is set — otherwise searches the web for polls and writes them `manually_verified=True` **immediately, with no human review step** (`poll_discovery.py`) — this DOES move the published forecast on the next recompute. See that module's docstring for the accuracy tradeoff. |
| `discover_parties_via_ai_task` | `FORECAST_RECOMPUTE_INTERVAL_MINUTES` | No-ops unless `OPENAI_API_KEY` is set — otherwise searches the web for electoral lists/parties not yet in the database (`party_discovery.py`); registration status is still clamped to the "considering" family, since that clamp is about not asserting an unconfirmed legal outcome, not about requiring a human. |
| `estimate_coalition_likelihoods_via_ai_task` | `FORECAST_RECOMPUTE_INTERVAL_MINUTES` | No-ops unless `OPENAI_API_KEY` is set — otherwise asks the model for its own numeric estimate of coalition-formation likelihood per party pair (`coalition_likelihood.py`) — an AI guess, always labeled as such, never a calibrated statistic. See `docs/COALITION_MODEL.md` section C. |
| `maybe_recompute_forecast_task` | `FORECAST_RECOMPUTE_INTERVAL_MINUTES` (default 60) | Re-runs the forecast if a new verified poll exists (manually entered, or AI-discovered — both set the same flag) — never on unverified data. |
| `scan_coalition_signals_task` | nightly, 02:00 UTC | Re-extracts `coalition_with`/`joint_list_with` relationships from recent articles and drafts low-confidence `CoalitionEvidence` rows — this one still stays low-confidence/drafted rather than auto-verified, since it's evidence about a specific claim, not a numeric estimate. |

Set `NLP_PROVIDER` and the matching API key in `.env` (`anthropic_compatible`
+ `ANTHROPIC_API_KEY`, or `openai_compatible` + `OPENAI_API_KEY`) to enable
LLM-backed extraction instead of the zero-dependency rules-based default
— see `services/ingestion/ingestion/nlp/`. Entity resolution
(`tasks.py::_resolve_party_mention`) is intentionally a simple
exact/alias name match, not the full fuzzy/transliteration resolver spec
section 10 describes — a real deployment handling ambiguous or
transliterated names should replace it before trusting auto-drafted
evidence at scale.

## What's not built yet for production readiness

- CI does not currently deploy anywhere (see `.github/workflows/ci.yml` —
  lint/build/test only).
- No infrastructure-as-code (Terraform/Pulumi/etc.) for a specific cloud
  provider — this is deliberately left open since the spec does not name
  one.
- No monitoring/alerting stack wired up (see `docs/MODEL_VALIDATION.md`
  and README for what observability hooks exist).
