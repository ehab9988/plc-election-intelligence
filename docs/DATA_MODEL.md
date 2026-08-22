# Data Model

Full table definitions: `services/api/app/models/*.py`. This is a
narrative index, not a duplicate of the code.

| Table(s) | File | Notes |
|---|---|---|
| `elections`, `election_rule_sets`, `election_timelines` | `election.py` | Versioned rules — see `docs/ELECTORAL_RULES.md` |
| `parties`, `party_aliases`, `people`, `person_aliases`, `party_person_relationships`, `party_party_relationships` | `party.py` | Typed, sourced, time-bounded relationships — never a bare "belongs to" field (section 10) |
| `electoral_lists`, `electoral_list_parties`, `candidates`, `candidate_rankings` | `electoral.py` | A list's public name can differ from its parent party's name (section 9) |
| `geographic_areas` | `geo.py` | Self-referencing hierarchy: country → region → governorate → locality |
| `news_sources`, `articles`, `article_entities`, `political_events` | `news.py` | Full articles never stored — metadata + permitted snippet only (section 8) |
| `pollsters`, `pollster_ratings`, `polls`, `poll_questions`, `poll_results`, `poll_geographic_results` | `polling.py` | See `docs/POLLING_METHOD.md` |
| `forecast_runs`, `forecast_party_results`, `forecast_candidate_results`, `forecast_distributions`, `simulations_summary` | `forecast.py` | Immutable once created (section 39) |
| `coalition_scenarios`, `coalition_evidence` | `coalition.py` | See `docs/COALITION_MODEL.md` |
| `sources`, `citations`, `entity_conflicts` | `provenance.py` | Every fact traces to a `Citation` → `Source`; conflicting claims are stored, never silently resolved (section 26) |
| `users`, `subscriptions`, `notifications`, `audit_logs`, `api_keys` | `auth.py` | RBAC (`UserRole`), immutable audit trail |

## Conventions

- UUID primary keys everywhere (`UUIDPrimaryKeyMixin`, `models/base.py`).
- All timestamps are timezone-aware UTC (`DateTime(timezone=True)`,
  `TimestampMixin`).
- Arabic and English names are stored in **separate columns**
  (`name_ar` / `name_en`), never a single localized-at-write-time field —
  the client picks which to render per its locale.
- Every status/confidence/type field that has a closed, meaningful set of
  values is a Postgres-native enum (`models/enums.py`), not a free string,
  so invalid states are rejected at the database layer.

## Registration status (section 5)

`RegistrationStatus` enum: `rumored → considering → announced_intention →
submitted_registration → provisional → officially_approved`, plus
`rejected` / `withdrawn` / `disqualified`. Both `Party` and
`ElectoralList` carry this status plus `registration_status_source_id`,
`registration_status_effective_date`, `registration_status_verified_at`,
and `registration_status_reason` — never just a boolean "is registered".

## Migrations

Alembic is configured (`services/api/alembic/`) against the full model
set. **No migration has been generated in this repository** — this
sandbox has no Python runtime to run
`alembic revision --autogenerate`. Generate the initial migration in a
real environment: see README "Database setup".
