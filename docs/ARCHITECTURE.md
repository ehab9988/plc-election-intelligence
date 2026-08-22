# Architecture

## Monorepo layout

```
apps/flutter_client/        Flutter app (Android + Windows, shared codebase)
services/api/                FastAPI REST API, SQLAlchemy models, Alembic migrations
services/forecasting/        Polling average + Monte Carlo + candidate/coalition math
services/ingestion/          News/document ingestion pipeline skeleton
packages/election_rules/     Electoral math engine — Dart (tested: `dart test`)
packages/election_rules_py/  Electoral math engine — Python port (mirrors the Dart tests)
infrastructure/              Docker/deployment-adjacent config
scripts/                     seed_data.py — vertical-slice seed script
docs/                        This directory
```

## Why the electoral math engine exists twice

The Flutter client and the Python backend both need the exact same
Sainte-Laguë/threshold/candidate-probability logic — the client for
displaying rule metadata and (in a future iteration) local what-if
simulation, the backend for producing real forecasts. Rather than expose
the backend as the only source of truth for math a client might want
offline, the algorithm is implemented once in Dart (the one runtime
available in this repo's build sandbox — see README "What could be
verified") with a full test suite, and ported line-by-line to Python for
the backend. Both files carry a comment pointing at the other and
instructing that any change be made in both places and re-verified with
`dart test`.

## Request flow (vertical slice)

```
Flutter client (Dio)
  → FastAPI (services/api/app/api/v1/*)
    → SQLAlchemy models (services/api/app/models/*)
    → forecast_runner.run_and_persist_forecast
        → forecasting.polling_average.compute_polling_average
        → forecasting.monte_carlo.run_monte_carlo
            → election_rules_py.allocate_seats_sainte_lague   (per iteration)
        → forecasting.candidate_forecast.compute_candidate_forecasts
        → persists ForecastRun / ForecastPartyResult / ForecastCandidateResult
            / ForecastDistribution / SimulationsSummary (immutable, section 39)
  ← JSON (schemas/*.py) ← Flutter models (lib/models/*.dart) ← screens
```

## Why the Flutter app ships with bundled demo data

This build's sandbox has no Python runtime and no Docker, so the backend
could not actually be started to serve the client during development (see
README). Rather than leave the UI unbuildable/unverifiable, every
repository (`lib/data/*_repository.dart`) tries the live API first and
falls back to a bundled fixture (`lib/data/fixtures/demo_fixture.dart`)
that mirrors exactly what `scripts/seed_data.py` would write to a real
database from the same August 2026 PCPSR test fixture. This also happens
to satisfy spec section 35 (offline mode) and section 67 (never blank the
UI on a fetch failure) for free — a toggle in Settings switches out of
demo mode once a real API is reachable.

## Renaming the product

`AppConfig.productName` (Flutter) and `Settings.product_name` (API,
`services/api/app/config.py`) are the two places the display name lives.
Both default to "PLC Election Intelligence" and are read everywhere else
in the app/API rather than being hard-coded per screen/response.
