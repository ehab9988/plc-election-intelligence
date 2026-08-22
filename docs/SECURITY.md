# Security

## Authentication

JWT access + refresh tokens (`services/api/app/core/security.py`), issued
on `/api/v1/auth/login` (OAuth2 password-grant form). Passwords are hashed
with bcrypt via `passlib`. `JWT_SECRET_KEY` must be set via environment
variable in production — `.env.example` ships an obviously-fake default
and the config loader (`services/api/app/config.py`) never falls back to
a value that looks production-safe.

## Authorization (RBAC)

`UserRole`: `user < premium < analyst < editor < administrator`
(`services/api/app/models/enums.py`). `core/deps.py::require_role(role)`
is a FastAPI dependency that rejects with 403 if the authenticated user's
rank is below the required role. Example: `POST /forecast/run` requires
`analyst` or above (`services/api/app/api/v1/forecast.py`).

## Audit logging

`AuditLog` (`services/api/app/models/auth.py`) is designed as
append-only: rows are never updated, only inserted, capturing
`user_id`, `action`, `entity_type`/`entity_id`, `previous_value`/
`new_value` (JSONB), `reason`, and an optional `source_id`. **Not yet
wired into every admin mutation endpoint in this build** — the model and
the intended usage pattern exist; automatically logging every analyst/admin
write is a follow-up (see README "What's not built yet").

## Injection / validation

All database access goes through SQLAlchemy's parameterized query builder
(`select(...)`) — no raw string-interpolated SQL anywhere in the
codebase. All request/response bodies are validated by Pydantic schemas
(`services/api/app/schemas/*.py`).

## CORS

Configured via `CORS_ALLOW_ORIGINS` (`.env.example`) — defaults to
`localhost:3000` only; must be set explicitly for any real deployment
origin.

## Secrets

`.env.example` documents every secret this system uses. `.gitignore`
excludes `.env`. Nothing in the codebase reads a secret from a hard-coded
string.

## Rate limiting

`ApiKey.rate_limit_per_minute` is modeled for the commercial API (section
37) but no rate-limiting middleware is wired up in this build — see
README "What's not built yet".
