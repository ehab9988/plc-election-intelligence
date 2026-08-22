# Static GitHub Deployment (No Server, No Database Host)

The simplest of the three deployment paths in this repo (the other two:
`docs/DEPLOYMENT.md` for a real server + Celery worker, and
`docs/FREE_TIER_DEPLOYMENT.md` for a free-tier hosted API). This one runs
**nothing continuously anywhere** — no FastAPI process, no Postgres, no
Docker, not even a free-tier host. GitHub itself is the entire backend:

| Piece | Where |
|---|---|
| Database | A SQLite file committed to this repo (`data/.state/plc_election.db`) |
| Data processing | A GitHub Actions job, on a schedule, on a fresh runner each time |
| "API" | Static JSON files committed to this repo (`data/`), read directly from `raw.githubusercontent.com` |
| Client | The Flutter app's `DataSource.staticGithub` mode |

This is a legitimate trade: no interactive write endpoints (no auth, no
admin review UI, no on-demand "run a forecast now" button, no live
`POST /coalitions/simulate`), in exchange for genuinely zero ongoing setup
or cost. Coalition-lab simulation still works — see "What can't work this
way" below for how.

## How it works

`.github/workflows/publish-static-data.yml` runs on a schedule
(`*/30 * * * *`, plus a daily deeper coalition-signal scan) and on manual
dispatch:

1. Checks out the repo, including the previously-committed SQLite file at
   `data/.state/plc_election.db`. On the very first run, that file
   doesn't exist yet, so the job seeds it (`scripts/seed_data.py`) with
   the same election/rules/parties/PCPSR-poll fixture the other
   deployment paths use as a starting point.
2. Runs one ingestion cycle (`scripts/run_ingestion_cycle.py` — the exact
   same code `docs/FREE_TIER_DEPLOYMENT.md`'s scheduler runs, just
   pointed at this SQLite file via `DATABASE_URL` instead of a hosted
   Postgres): fetches configured RSS sources (if any), **actively
   searches the web for recent news and polls via OpenAI's `web_search`
   tool if `OPENAI_API_KEY` is set** (no per-outlet feed URL needed —
   `sources/openai_search_adapter.py` and `poll_discovery.py`), dedupes,
   runs NLP extraction, drafts coalition evidence, and recomputes the
   forecast if a new manually-verified poll exists. AI-discovered polls
   are always stored **unverified** and cannot move the published
   forecast until an analyst reviews and verifies them — see
   `poll_discovery.py`'s module docstring for why that gate matters.
3. Runs `scripts/export_static_data.py`, which re-derives every JSON file
   under `data/` from the current database state — the exact same
   Pydantic schemas and router functions the live FastAPI endpoints use
   (see that script's docstring), so the JSON shape here is always
   identical to what a live API would return for the same data.
4. Commits and pushes `data/` (both the SQLite file and the JSON
   snapshot) back to the repo if anything changed.

The Flutter client, in `DataSource.staticGithub` mode (the default),
fetches those JSON files directly:

```
https://raw.githubusercontent.com/<owner>/<repo>/main/data/elections/current.json
https://raw.githubusercontent.com/<owner>/<repo>/main/data/forecast/latest/<election_id>.json
...
```

## Path convention

Query parameters have no meaning to a static file host, so anywhere the
live API takes one, the static export folds it into the file path
instead. Both sides of this convention are defined in exactly two places
that must be kept in sync: `scripts/export_static_data.py` (writer) and
`apps/flutter_client/lib/data/*_repository.dart` (reader, via
`RemoteFetch.fetch(livePath, staticPath)` in `remote_fetch.dart`).

| Live API | Static file |
|---|---|
| `GET /elections/current` | `elections/current.json` |
| `GET /elections/{id}/rules` | `elections/{id}/rules.json` |
| `GET /elections/{id}/timeline` | `elections/{id}/timeline.json` |
| `GET /forecast/latest?election_id={id}` | `forecast/latest/{id}.json` |
| `GET /forecast/history?election_id={id}` | `forecast/history/{id}.json` |
| `GET /parties?q=...` | `parties.json` (client-side substring filter — see below) |
| `GET /electoral-lists?election_id={id}` | `electoral_lists.json` (single-election app, so unfiltered) |
| `GET /candidates?electoral_list_id={id}` | `candidates/by-list/{id}.json` |
| `GET /candidates/{id}` | `candidates/{id}.json` |
| `GET /polls?election_id={id}` | `polls.json` (single-election app, so unfiltered) |
| `GET /polling-average?election_id={id}` | `polling-average.json` |
| `GET /news` | `news.json` |
| `GET /coalitions?party_id={id}` (or none) | `coalitions/by-party/{id}.json` / `coalitions/all.json` |

## What can't work this way

- **`POST /coalitions/simulate`** has no static equivalent (it's a
  write-shaped request). `CoalitionRepository.simulate()` instead
  reproduces the exact same approximation the live endpoint itself runs
  (`services/api/app/api/v1/coalitions.py` — summing per-list seat
  medians/ranges from the published forecast; see that file's docstring
  for why it's an approximation even server-side) directly in Dart,
  against the fetched `forecast/latest/{id}.json`. Same math, computed
  client-side instead of server-side — not a lesser estimate.
- **Auth, the admin review UI, rate limiting, billing** — all still
  require a real server; this path doesn't attempt them.
- **Search-as-you-type filtering** (`/parties?q=`) degrades to "fetch
  the full list, filter client-side" — fine at this app's data scale
  (dozens of parties), would not scale to thousands.

## Setup

1. Make sure the repo is public (required for GitHub Actions minutes to
   be free/unrestricted — see `docs/FREE_TIER_DEPLOYMENT.md`'s scheduler
   section for the same caveat and the private-repo alternative).
2. That's it for a fresh clone — `.github/workflows/publish-static-data.yml`
   is already in the repo and will seed + publish on its own schedule, or
   trigger it manually now: Actions tab -> "Publish Static Data" -> Run
   workflow.
3. Optionally add a repository secret `OPENAI_API_KEY` — this both
   enables LLM-backed extraction (set the repository variable
   `NLP_PROVIDER=openai_compatible` to use it for that) and, independently,
   turns on active web-search discovery of news and polls with zero
   per-outlet configuration. `ANTHROPIC_API_KEY` is also supported for
   extraction only (see `docs/FREE_TIER_DEPLOYMENT.md`), but does not
   enable discovery — only OpenAI's `web_search` tool is wired up for
   that in this build.
4. In the Flutter client, Settings -> Data source -> "Static (GitHub)"
   (the default) -> confirm the base URL reads
   `https://raw.githubusercontent.com/<owner>/<repo>/main/data` for your
   fork -> Save.

## Running it yourself, locally, without waiting for a scheduled run

```bash
cd services/api
pip install -r requirements.txt

DATABASE_URL=sqlite:///./dev.db python ../../scripts/seed_data.py
DATABASE_URL=sqlite:///./dev.db python ../../scripts/run_ingestion_cycle.py
DATABASE_URL=sqlite:///./dev.db python ../../scripts/export_static_data.py
```

Inspect the generated `data/` directory directly, or point the Flutter
client's Settings -> Data source -> "Live API" at a locally-running
`uvicorn app.main:app` instead if you want to iterate against a real
server (see the README's "no Docker, no Postgres" quickstart).

## Honest limitations

- **AI news/poll discovery was not exercised against a real OpenAI
  account.** `sources/openai_search_adapter.py` and `poll_discovery.py`
  were written against the OpenAI Responses API's `web_search` tool and
  structured-output (`json_schema`) support, but no `OPENAI_API_KEY` or
  network egress was available in this development sandbox to actually
  call it. The exact tool name and response shape have changed across
  OpenAI SDK versions — verify both against current OpenAI docs, and
  trigger the workflow manually with `OPENAI_API_KEY` set once to confirm
  it works, before relying on the schedule. If the tool name has changed,
  the adapter fails closed (logs and returns no documents / no polls;
  never fabricates a result), it doesn't silently invent data.
- **Poll discovery quality depends entirely on what the model finds and
  reports faithfully.** The prompt instructs it to never invent numbers
  and to always cite a real `source_url`, and every discovered poll is
  stored `manually_verified=False` specifically because that instruction
  cannot be verified in code — an analyst must check each discovered
  poll's `source_url` before verifying it. This is a hard requirement,
  not a suggestion: nothing in this codebase auto-verifies an
  AI-discovered poll.
- **Git-as-database bloat.** `data/.state/plc_election.db` is committed
  on every run that changes it. SQLite files compress reasonably well in
  git's delta storage, but this will grow the repo's `.git` size
  meaningfully over months of 30-minute-cadence runs. When this becomes a
  problem: switch to `docs/FREE_TIER_DEPLOYMENT.md`'s free hosted Neon/
  Supabase Postgres instead of a committed SQLite file — the ingestion
  code itself (`services/ingestion/ingestion/jobs.py`) doesn't change,
  only `DATABASE_URL`.
- **All the GitHub Actions scheduling caveats already documented in
  `docs/FREE_TIER_DEPLOYMENT.md`** apply here unchanged: schedule timing
  isn't exact under GitHub load, and scheduled workflows auto-disable
  after 60 days of repository inactivity.
- **Eventual consistency, not real-time.** Data is at most one cron
  interval (30 minutes) stale, and the client itself does not know how
  stale — it doesn't currently read `data/meta.json`'s `generated_at`
  timestamp. Reading and surfacing that (matching the "Forecast updated
  {time}" pattern the live API's `data_cutoff_at` already drives
  elsewhere in the UI) is a natural follow-up, not yet wired.
- **This SQLite-backed path was exercised locally in this build**
  (`export_static_data.py` and the seed/ingestion scripts were actually
  run against a real SQLite database, and the Flutter side was verified
  against the resulting JSON), **but the GitHub Actions workflow itself
  was not** — no GitHub Actions runner is available in this development
  sandbox. Trigger it manually once (Actions tab -> "Publish Static
  Data" -> Run workflow) and check the run log before relying on the
  schedule.
