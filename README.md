# PLC Election Intelligence

A Palestinian election intelligence, polling, and parliamentary-forecasting
platform: transparent poll aggregation, statistically defensible seat
forecasts, closed-list candidate seat probabilities, and an interactive
coalition lab — with every number traceable to a source and every forecast
carrying an explicit model version, data cutoff, and uncertainty range.

"PLC Election Intelligence" is a working name. See "Renaming" below.

## What this is (and isn't)

This is a real, structured monorepo with working code across the full
stack described in the product spec — not just a plan. It includes:

- A **tested** electoral-mathematics engine (Sainte-Laguë seat allocation,
  thresholds, majority calculation, closed-list candidate seat
  probability) — 24/24 tests passing via `dart test`.
- A **built and tested** Flutter client (Android + Windows, shared
  codebase) — `flutter analyze` clean, `flutter test` passing (9/9), and
  `flutter build windows --release` succeeds. Includes working Arabic/RTL
  (verified by an automated locale-switch test) and PDF report export for
  parties, candidates, forecasts, and coalition scenarios.
- A complete, **installed-and-tested** FastAPI + SQLAlchemy backend (36
  tables across elections, parties, people, polls, forecasts, coalitions,
  news, provenance, auth) with a working forecast pipeline (polling
  average → Monte Carlo simulation → seat/candidate/coalition
  probabilities) — 36/36 Python tests passing (`election_rules_py` 22,
  `forecasting` 5, `api` 4, `ingestion` 5) — see "What could not be
  verified" below for the one caveat that remains (no live Postgres in
  this sandbox, so the ORM layer is verified against SQLite instead).
- A Celery-based 24/7 ingestion scheduler (RSS fetch → dedupe → LLM-backed
  extraction → coalition-signal drafting → conditional forecast
  re-computation) with a Claude-backed and an OpenAI-compatible
  `PoliticalNlpProvider`, both using a strict JSON-schema extraction
  contract. Written and internally consistent; **requires a deployed,
  long-running process to actually run 24/7** — see "Dynamic /
  continuously-updating data" below.
- Coalition Lab evidence seeded with **real, cited news** (not
  fabricated): Al Jazeera's Aug 19, 2026 reporting on Hamas/Islamic
  Jihad/PFLP/National Initiative/Dahlan-faction alliance talks, and
  Fatah's stated refusal to join a joint list with Hamas — see
  `scripts/seed_data.py`.
- A **no-server deployment path**: `scripts/export_static_data.py` +
  `.github/workflows/publish-static-data.yml` publish a static JSON
  snapshot straight to this repo on a schedule, which the Flutter client
  reads directly from `raw.githubusercontent.com` — no FastAPI process,
  no Postgres, no hosting account of any kind. See
  `docs/STATIC_GITHUB_DEPLOYMENT.md`. This is the client's default data
  source.

It is explicitly **not** a finished, production-hardened commercial
product: several sections of the original spec (admin review UI, live
CEC results ingestion, billing integration, rate limiting, a full
Bayesian state-space forecast layer) are architected with clear extension
points but not built out — each is called out honestly in `docs/*.md`
rather than silently assumed complete.

## Repository layout

```
apps/flutter_client/         Flutter app — Android + Windows
services/api/                 FastAPI REST API
services/forecasting/         Polling average + Monte Carlo engine
services/ingestion/           News ingestion pipeline (skeleton)
packages/election_rules/      Electoral math — Dart, tested in this repo
packages/election_rules_py/   Electoral math — Python port (mirrors the Dart tests)
scripts/seed_data.py          Vertical-slice seed script (PCPSR Aug 2026 fixture)
docs/                         Architecture, data model, methodology, security, etc.
docker-compose.yml            postgres + redis + api
```

## What could not be verified in this build

An earlier build of this repo was written in a sandbox with **no working
Python interpreter, no Docker, no Node, no Android SDK** — only
Flutter/Dart were available there, so the entire Python backend was
written but never installed or executed. A later session had a real
Python 3.13 interpreter (still no Docker, so no local Postgres/Redis) and
used it to actually verify the backend:

- Installed `packages/election_rules_py`, `services/forecasting`,
  `services/api`, and `services/ingestion` into a virtualenv — all four
  install cleanly with no dependency conflicts.
- Ran `pytest` across all four: **36/36 passing**
  (`election_rules_py` 22, `forecasting` 5, `api` 4, `ingestion` 5).
- Fixed a real portability bug this surfaced: the ORM models used
  `sqlalchemy.dialects.postgresql.UUID` / `JSONB` / `ARRAY` directly,
  which don't compile under SQLite. Added
  `services/api/app/models/types.py` — portable `UUID`/`JSONB`/`ARRAY`
  `TypeDecorator`s that delegate to the native Postgres types when the
  dialect is `postgresql` (zero behavior change in production) and fall
  back to a portable representation otherwise (`CHAR(36)`, `JSON`,
  JSON-encoded list). All 11 model files were updated to import from
  `.types` instead of `sqlalchemy.dialects.postgresql` directly. This is
  what lets `test_forecast_runner.py`'s in-memory-SQLite fixture actually
  run.

Still not verified anywhere, because no Docker/Postgres/Redis has been
available in any sandbox so far:
- No Alembic migration has been generated (needs a live Postgres to run
  `alembic revision --autogenerate` meaningfully — generating one against
  SQLite would risk baking in SQLite-specific DDL and silently mislabeling
  it as Postgres-correct, so this was deliberately left undone rather than
  faked).
- No Docker image was built or run; no real Postgres/Redis integration
  test (schema was only exercised against SQLite via the portable types
  above — JSONB/ARRAY *storage semantics* like containment queries are
  Postgres-only and untested here).
- No Android build was produced (no Android SDK available in any sandbox
  so far; `flutter build windows --release` **was** run successfully in
  the original build as evidence the shared codebase compiles for a real
  target).

**Before relying on the backend in production, a developer with Docker
or a real Postgres instance should**: bring up Postgres, generate and run
the initial Alembic migration, re-run `pytest` against that real database
(not just SQLite) to confirm the portable types round-trip identically,
then run `scripts/seed_data.py` and hit `/api/v1/forecast/latest`. The
Flutter client's Settings screen can then be pointed at that live API
(Settings → Data source → "Live API").

## Getting started

### Prerequisites

- Flutter 3.27+ / Dart 3.12+ (client requires Dart `^3.12.2`; verified
  against Flutter 3.47.1 / Dart 3.13.1)
- Python 3.13+ (for the backend; verified in this build — no Postgres
  needed for local dev, see the SQLite quickstart below)
- Docker + Docker Compose — only needed for the Postgres production path;
  not required for local dev or the static-GitHub deployment path

### Flutter client (works today, out of the box)

```bash
cd apps/flutter_client
flutter pub get
flutter gen-l10n      # regenerates lib/l10n/generated/ if you edit the .arb files
flutter analyze       # clean in this build
flutter test          # 9/9 passing in this build

# Windows desktop
flutter run -d windows
# or a release build:
flutter build windows --release

# Android (requires Android SDK + a connected device/emulator)
flutter run -d <android-device-id>
```

There is no "demo mode" — the client always renders real data, from one
of two sources (Settings → Data source):
- **Static (GitHub)**, the default: reads the JSON snapshot published by
  `.github/workflows/publish-static-data.yml` directly from
  `raw.githubusercontent.com` — no server required. See
  `docs/STATIC_GITHUB_DEPLOYMENT.md`.
- **Live API**: a running `services/api` instance (see below).

`flutter test` doesn't depend on either — the widget test suite overrides
the data providers directly with an offline fixture
(`test/fixtures/demo_fixture.dart`, `test/helpers/fixture_overrides.dart`)
so it runs deterministically with no network.

### Backend — quickest path: no Docker, no Postgres (verified working)

For local dev, with no Docker or Postgres install available, the API can
run directly against a SQLite file — the ORM's portable
`UUID`/`JSONB`/`ARRAY` types (`app/models/types.py`) make this safe; it
delegates to native Postgres types automatically when `DATABASE_URL`
is a `postgresql+psycopg://...` URL instead.

```bash
cd services/api
python -m venv .venv && source .venv/bin/activate   # or Windows equivalent
pip install -r requirements.txt

cat > .env <<'EOF'
DATABASE_URL=sqlite:///./dev.db
JWT_SECRET_KEY=local-dev-only-not-for-production
EOF

# Creates the schema (Base.metadata.create_all — no Alembic migration
# needed for this path) and seeds one election, its verified 2026 rule
# set, parties/lists/candidates, the PCPSR Aug 2026 poll fixture, and a
# published 20,000-simulation forecast run:
python ../../scripts/seed_data.py

# Run the API:
uvicorn app.main:app --reload
# Swagger UI: http://localhost:8000/docs
```

Then in the Flutter client, Settings → Data source → **Live API** (the
default API base URL, `http://localhost:8000/api/v1`, already matches)
and Save.

### Backend — production path: Postgres via Docker Compose

```bash
cd services/api
python -m venv .venv && source .venv/bin/activate   # or Windows equivalent
pip install -r requirements.txt

cp ../../.env.example ../../.env   # edit secrets/DB URL as needed

# Bring up Postgres + Redis:
docker compose -f ../../docker-compose.yml up -d postgres redis

# Generate + apply the initial migration (none exists yet in this repo —
# needs a real Postgres connection to autogenerate correctly; see "What
# could not be verified" above for why this wasn't generated against
# SQLite instead):
alembic revision --autogenerate -m "initial schema"
alembic upgrade head

python ../../scripts/seed_data.py

uvicorn app.main:app --reload
# Swagger UI: http://localhost:8000/docs
```

Or via Docker Compose for the whole backend stack:

```bash
cp .env.example .env
docker compose up --build
```

### Dynamic / continuously-updating data

**"Live 24/7 data" requires a deployed, always-running process — no AI
agent session, including the one that wrote this code, can leave a
background job running after it ends.** This repo runs entirely on the
genuinely $0 path by default: **`docs/STATIC_GITHUB_DEPLOYMENT.md`** —
no server, no database host, just a GitHub Actions job
(`.github/workflows/publish-static-data.yml`) on a schedule, committing
its own SQLite database and a static JSON snapshot back to the repo.

A second $0-ish path also exists on paper — free Postgres (Neon/Supabase)
+ free API hosting (Render) + GitHub Actions as scheduler, see
**`docs/FREE_TIER_DEPLOYMENT.md`** — but its scheduler workflow
(`ingestion-cron.yml`) was removed from this repo after it sat failing
on every scheduled tick with no `DATABASE_URL` secret configured (nobody
was using that path). Recreate it from `docs/FREE_TIER_DEPLOYMENT.md` if
you actually want a hosted-Postgres deployment instead of the static one.

The rest of this section covers the alternative if you do have a server
to run a real Celery worker on:

```bash
cd services/ingestion
pip install -r requirements.txt
celery -A ingestion.celery_app worker --beat -l info
```

This continuously: fetches configured RSS `NewsSource` rows, extracts
structured entities/events/coalition signals via Claude or an
OpenAI-compatible model (set `NLP_PROVIDER=anthropic_compatible` +
`ANTHROPIC_API_KEY`, or `NLP_PROVIDER=openai_compatible` +
`OPENAI_API_KEY`, in `.env`), drafts `CoalitionEvidence` rows for analyst
review, and re-runs the forecast whenever a new **manually-verified** poll
appears — see `docs/DEPLOYMENT.md` "24/7 ingestion & forecasting" for the
full schedule and what each task does. Nothing here fabricates a poll or
news article that doesn't exist — the scheduler only processes real
fetched content, and (per CRITICAL ACCURACY RULE #6/#53) auto-drafted
coalition evidence is never marked verified without a human review step.

### Tests

```bash
# Verified with Flutter/Dart:
cd packages/election_rules && dart pub get && dart test   # 24/24 passing
cd apps/flutter_client && flutter test                     # 9/9 passing

# Verified with Python 3.13 (no Docker/Postgres/Redis, so against SQLite
# for the ORM layer — see "What could not be verified" above):
cd packages/election_rules_py && pip install -e . && pytest   # 22/22 passing
cd services/forecasting && pip install -r requirements.txt pytest && pytest   # 5/5 passing
cd services/api && pip install -r requirements.txt && pytest                  # 4/4 passing
cd services/ingestion && pip install -r requirements.txt && pytest            # 5/5 passing
```

## Methodology, at a glance

- **Polling average**: weighted by recency, sample size, population type,
  and pollster quality — never naive arithmetic averaging, never mixes
  differently-worded questions. See `docs/POLLING_METHOD.md`.
- **Forecast**: Dirichlet Monte Carlo over the polling average, with
  house-effect/turnout noise and configurable undecided-voter allocation.
  The full Bayesian dynamic state-space latent-support model described in
  the spec is architected (`LatentSupportModel` protocol) but not yet
  implemented — stated plainly in `docs/FORECAST_MODEL.md`, not hidden.
- **Seats**: exact, tested Sainte-Laguë allocation against a versioned
  `ElectionRuleSet` (132 seats, 1% threshold for the 2026 baseline).
  Majority threshold is always `floor(total_seats/2)+1`, never a literal
  `67`. See `docs/ELECTORAL_RULES.md`.
- **Candidates**: seat probability is always `P(list seats >= rank)` from
  simulation data — never a fabricated individual vote share (closed-list
  system). See `docs/ELECTORAL_RULES.md`.
- **Coalitions**: mathematical majority feasibility (objective, from
  simulations) is always shown separately from political compatibility
  (evidence-based, never a fabricated formation probability). See
  `docs/COALITION_MODEL.md`.

Full docs: `docs/ARCHITECTURE.md`, `docs/DATA_MODEL.md`,
`docs/ELECTORAL_RULES.md`, `docs/FORECAST_MODEL.md`,
`docs/POLLING_METHOD.md`, `docs/COALITION_MODEL.md`,
`docs/DATA_SOURCES.md`, `docs/SOURCE_LICENSING.md`, `docs/API.md`,
`docs/SECURITY.md`, `docs/DEPLOYMENT.md`, `docs/FREE_TIER_DEPLOYMENT.md`,
`docs/STATIC_GITHUB_DEPLOYMENT.md`,
`docs/MODEL_VALIDATION.md`.

## What's not built yet

Tracked honestly rather than silently assumed done:

- Admin/analyst review UI (poll approval queue, entity merge, source
  conflict resolution) — underlying tables exist, screens do not.
- Live CEC results ingestion adapter (section 62) — interface only.
- Billing integration (Google Play Billing / external checkout) —
  `Subscription` model exists, no payment flow wired up.
- Rate limiting / API-key enforcement for the commercial API tier.
- A real backtesting run (`/model-performance` intentionally returns `[]`
  rather than a fabricated number — see `docs/MODEL_VALIDATION.md`).
- Full per-screen Flutter localization: Arabic/English switching works
  now (Settings → Language; verified by
  `test/widget/arabic_locale_test.dart`, which asserts real RTL and real
  translated nav labels), and primary screens (nav, Dashboard, Forecast,
  Coalition Lab, Settings, PDF reports) are wired to `AppLocalizations`.
  Some secondary screens (Polls, Parties list, News, Candidate detail body
  text) still have a handful of hardcoded English strings — the
  infrastructure and translations exist in the ARB files, remaining
  screens are a follow-up.
- Drift-based structured offline cache (spec section 6 suggests Drift);
  this build uses `shared_preferences` for simple config only — no local
  data cache, which is materially simpler than a queryable local cache.
- Automatic entity resolution (spec section 10): the ingestion worker's
  `_resolve_party_mention` is a simple exact/alias name match, not the
  fuzzy/transliteration-aware resolver a production deployment needs —
  see `docs/DEPLOYMENT.md`.
- A dedicated `article_relationships` table: `scan_coalition_signals_task`
  currently re-runs NLP extraction against recently-stored article
  snippets rather than reading persisted relationship rows, because this
  build's schema only stores entity mentions (`article_entities`), not
  relationships. Documented as a gap in `docs/DEPLOYMENT.md`, not hidden.
- The Celery worker path (`services/ingestion/ingestion/celery_app.py`) is
  written and internally consistent but requires a real server to run on
  and was not exercised here (no Postgres/Redis available in this
  sandbox). The GitHub Actions path
  (`.github/workflows/publish-static-data.yml`, calling
  `scripts/run_ingestion_cycle.py`) **is** deployed and running — see
  `docs/STATIC_GITHUB_DEPLOYMENT.md`.

## Renaming

Two places carry the product name: `AppConfig.productName`
(`apps/flutter_client/lib/core/app_config.dart`) and
`Settings.product_name` (`services/api/app/config.py`). Update both (plus
the Windows window title in
`apps/flutter_client/windows/runner/main.cpp` and the Android label in
`apps/flutter_client/android/app/src/main/AndroidManifest.xml`) to
rebrand.

## Data licensing

See `docs/SOURCE_LICENSING.md`. No commercial/licensed news API or
pollster API integration is included — this build only implements an RSS
adapter reference implementation, admin-entered content, and a
manually-transcribed test poll fixture with full citation.

## License / commercial use

This codebase is provided as an implementation for the requesting party;
no third-party license terms are bundled. Confirm licensing for any
external data source (news APIs, pollster APIs, map tiles, fonts) before
commercial launch — see `docs/SOURCE_LICENSING.md`.
