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
- A complete FastAPI + SQLAlchemy backend (36 tables across elections,
  parties, people, polls, forecasts, coalitions, news, provenance, auth)
  with a working forecast pipeline (polling average → Monte Carlo
  simulation → seat/candidate/coalition probabilities), written and
  internally consistent, but **not executed** in this build's sandbox —
  see "What could not be verified" below.
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
  `apps/flutter_client/lib/data/fixtures/demo_fixture.dart` and
  `scripts/seed_data.py`.

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

This build's development sandbox has:
- **Flutter/Dart**: available and used to actually build/analyze/test the
  client and the Dart electoral-math package.
- **No working Python interpreter** (only a Windows Store execution-alias
  stub), **no Docker**, **no Node**, **no Android SDK**.

Consequences, stated plainly:
- The Python backend (`services/api`, `services/forecasting`,
  `services/ingestion`, `packages/election_rules_py`) was written
  carefully — the Python electoral-math package is a direct line-by-line
  port of the Dart package that **is** fully tested — but could not be
  installed, run, or pytest-verified here. Every Python test file has a
  header noting this.
- No Alembic migration has been generated (needs a live Python + Postgres
  to run `alembic revision --autogenerate`).
- No Docker image was built or run.
- No Android build was produced (no Android SDK available; `flutter
  build windows --release` **was** run successfully as evidence the
  shared codebase compiles for a real target).

**Before relying on the backend, a developer with a real Python
environment should**: install `services/api/requirements.txt`, generate
and run the initial Alembic migration, run `pytest` across
`packages/election_rules_py`, `services/forecasting`, and `services/api`,
then run `scripts/seed_data.py` and hit `/api/v1/forecast/latest`. The
Flutter client's Settings screen can then be pointed at that live API
(toggle off "Demo mode").

## Getting started

### Prerequisites

- Flutter 3.44+ / Dart 3.12+ (verified against this exact version in this
  build)
- Python 3.12+ (for the backend — not available in this build's sandbox)
- Docker + Docker Compose (for Postgres/Redis — not available in this
  build's sandbox)

### Flutter client (works today, out of the box)

```bash
cd apps/flutter_client
flutter pub get
flutter gen-l10n      # regenerates lib/l10n/generated/ if you edit the .arb files
flutter analyze       # clean in this build
flutter test          # 4/4 passing in this build

# Windows desktop
flutter run -d windows
# or a release build:
flutter build windows --release

# Android (requires Android SDK + a connected device/emulator)
flutter run -d <android-device-id>
```

The client ships in **Demo mode** by default (Settings → Demo mode), so
it renders real screens with the bundled August 2026 PCPSR fixture data
even with no backend running — this is what `flutter test` exercises.
Turn Demo mode off and set an API base URL once a live backend is
reachable.

### Backend (written, not run in this sandbox — commands for a real environment)

```bash
cd services/api
python -m venv .venv && source .venv/bin/activate   # or Windows equivalent
pip install -r requirements.txt

cp ../../.env.example ../../.env   # edit secrets/DB URL as needed

# Bring up Postgres + Redis:
docker compose -f ../../docker-compose.yml up -d postgres redis

# Generate + apply the initial migration (none exists yet in this repo):
alembic revision --autogenerate -m "initial schema"
alembic upgrade head

# Seed the vertical-slice fixture (election, rules, parties, lists,
# candidates, the PCPSR Aug 2026 poll, and a published forecast run):
python ../../scripts/seed_data.py

# Run the API:
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
background job running after it ends.** That doesn't require a paid
server, though: see **`docs/FREE_TIER_DEPLOYMENT.md`** for a genuinely
$0 path — free Postgres (Neon/Supabase) + free API hosting (Render) +
GitHub Actions as the scheduler (unlimited/free on a public repo, already
configured in `.github/workflows/ingestion-cron.yml`). The rest of this
section covers the alternative if you do have a server to run a real
Celery worker on:

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
# Verified in this build:
cd packages/election_rules && dart pub get && dart test   # 24/24 passing
cd apps/flutter_client && flutter test                     # 9/9 passing

# Written but not executed in this build (needs a real Python env):
cd packages/election_rules_py && pip install -e .[dev] && pytest
cd services/forecasting && pip install -r requirements.txt pytest && pytest
cd services/api && pip install -r requirements.txt && pytest
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
  this build uses `shared_preferences` for simple config + the bundled
  demo fixture for offline rendering, which is materially simpler than a
  queryable local cache.
- Automatic entity resolution (spec section 10): the ingestion worker's
  `_resolve_party_mention` is a simple exact/alias name match, not the
  fuzzy/transliteration-aware resolver a production deployment needs —
  see `docs/DEPLOYMENT.md`.
- A dedicated `article_relationships` table: `scan_coalition_signals_task`
  currently re-runs NLP extraction against recently-stored article
  snippets rather than reading persisted relationship rows, because this
  build's schema only stores entity mentions (`article_entities`), not
  relationships. Documented as a gap in `docs/DEPLOYMENT.md`, not hidden.
- Both scheduler paths — the Celery worker (`services/ingestion/ingestion/celery_app.py`)
  and the GitHub Actions cron workflow (`.github/workflows/ingestion-cron.yml`,
  calling `scripts/run_ingestion_cycle.py`) — are written and internally
  consistent but were never executed in this sandbox (no Python runtime,
  no Postgres, no GitHub Actions runner available here). One of them
  needs to actually be deployed/enabled for "ingest news 24/7, detect
  coalitions, readjust forecasts" to happen. See "Dynamic /
  continuously-updating data" above and `docs/FREE_TIER_DEPLOYMENT.md`.

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
