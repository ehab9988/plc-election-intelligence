# Free-Tier Deployment (No Server Required)

For running this platform for real with $0 in infrastructure cost. Three
pieces, each hosted somewhere different, none of them costing money at
this project's scale:

| Piece | Where | Cost |
|---|---|---|
| Database (Postgres) | Neon or Supabase free tier | Free |
| API (FastAPI) | Render free web service (or any free container host) | Free (sleeps when idle) |
| 24/7 scheduler | GitHub Actions scheduled workflow | Free, unlimited on a **public** repo |

GitHub itself only supplies the third piece — Actions is CI/scheduling
infrastructure, not a database or a place to host a listening web server.
The three together give you real continuous operation without a paid
server.

## 1. Database: Neon or Supabase (free Postgres)

Either works; both have a free tier with no credit card required for the
free plan. Pick one, create a project, and copy the connection string —
it should look like `postgresql://user:pass@host/dbname`. Convert it to
the SQLAlchemy-with-psycopg form this project expects:

```
postgresql+psycopg://user:pass@host/dbname
```

Then, from your own machine (needs a real Python environment — see
README "What could not be verified"):

```bash
cd services/api
pip install -r requirements.txt
DATABASE_URL="postgresql+psycopg://user:pass@host/dbname" alembic upgrade head
DATABASE_URL="postgresql+psycopg://user:pass@host/dbname" python ../../scripts/seed_data.py
```

## 2. API: Render free web service (or equivalent)

Render's free tier needs no credit card and can build directly from the
repo's `services/api/Dockerfile`. Equivalent options: Fly.io, Railway, or
Google Cloud Run — pick whichever you're comfortable creating an account
on; the Dockerfile is standard and portable.

Render setup:
1. New → Web Service → connect this GitHub repo.
2. Root/Dockerfile path: `services/api/Dockerfile`, build context: repo root.
3. Environment variables: at minimum `DATABASE_URL` (from step 1) and
   `JWT_SECRET_KEY` (any long random string — never reuse the
   `.env.example` placeholder).
4. Deploy. Render gives you a public URL like `https://your-app.onrender.com`.

**Known limitation of the free tier**: the service sleeps after ~15
minutes of no traffic and takes 30-60 seconds to wake on the next
request. Fine for a personal/demo deployment; not acceptable for a paying
user base — upgrading to a paid Render plan (or any always-on host) is
the fix once this matters.

## 3. 24/7 scheduler: GitHub Actions

**Not currently set up in this repo** — this project uses
`docs/STATIC_GITHUB_DEPLOYMENT.md`'s no-server path instead
(`.github/workflows/publish-static-data.yml`), which needs no
`DATABASE_URL` secret at all (its database is a SQLite file committed to
the repo, not this section's hosted Postgres). An earlier
`ingestion-cron.yml` workflow for *this* section's Postgres-backed path
was added and then removed after it sat failing on every scheduled tick
with no `DATABASE_URL` configured. Recreate it yourself if you actually
want this path — it's a small variant of
`publish-static-data.yml`: same dependency-install fix
(`pip install -r requirements.txt` from within `services/forecasting`
and `services/api`, not `pip install -e` alone — see that workflow's
comments for why), but point `DATABASE_URL` at your Neon/Supabase
instance via a repo secret instead of a committed SQLite file, and drop
the "bootstrap on first run" / "commit and push" steps entirely (a
real Postgres doesn't need either).

Wire it up:
1. Repo → Settings → Secrets and variables → Actions.
2. Add secrets: `DATABASE_URL` (same value as step 1), and optionally
   `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` if you want LLM-backed
   extraction instead of the free zero-dependency rules-based provider.
3. Add a repo **variable** (not secret) `NLP_PROVIDER` set to `rules`,
   `anthropic_compatible`, or `openai_compatible`.
4. Trigger the workflow manually first (Actions tab → Run workflow) to
   confirm the secrets are correct before waiting for the next scheduled
   tick — this exact failure mode (a blank `DATABASE_URL` producing a
   `sqlalchemy.exc.ArgumentError`) is what killed the previous attempt at
   this workflow, silently, on every 15-minute tick, until someone
   noticed.

### Honest limitations of this approach

- **Schedule timing isn't exact.** GitHub explicitly reserves the right
  to delay scheduled workflows during periods of high platform load — a
  "every 15 minutes" schedule might occasionally run late. Fine for a
  polling/news cadence; not a substitute for a real-time system.
- **Auto-disabled after 60 days of repo inactivity.** GitHub disables
  scheduled workflows if the *repository* (not the workflow) has had no
  commits for 60 days. If you're not actively developing the repo,
  either push a trivial commit occasionally, or use a free external
  pinger (e.g. cron-job.org, itself free) to call the GitHub REST API's
  `workflow_dispatch` endpoint on a schedule — that counts as activity
  and doesn't require a repo commit.
- **No persistent worker state.** Each run is a fresh, stateless VM —
  fine here because all state lives in the Postgres database, not in
  memory, but it means there's no long-running in-process cache the way
  a real Celery worker would have.
- **Ephemeral runner cold-start cost.** Each run reinstalls Python
  dependencies from scratch (~30-60s). Irrelevant at a 15-minute cadence;
  would matter if you tried to push the interval much lower.

## 4. Point the Flutter app at your free deployment

Settings → turn off Demo mode → API base URL → your Render URL + `/api/v1`
(e.g. `https://your-app.onrender.com/api/v1`) → Save.

## When you outgrow this

Everything here is a drop-in replacement path, not a dead end:
- Swap Render for any container host with an always-on plan when the
  cold-start sleep becomes a problem.
- Swap the GitHub Actions cron job for a real Celery worker + beat
  process (`docs/DEPLOYMENT.md` "24/7 ingestion & forecasting") when you
  have a server — `jobs.py` is shared by both paths, so nothing about the
  ingestion logic itself needs to change.
- Neon/Supabase both offer paid tiers with more compute/storage if the
  free Postgres tier's limits (connection count, storage, compute
  hours) become a bottleneck.
