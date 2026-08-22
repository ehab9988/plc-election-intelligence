# Data Sources

## Tiers (section 7)

| Tier | Examples | Default weight in polling average |
|---|---|---|
| 1 — Primary/authoritative | CEC, official election law, official CEC results/schedules | N/A — used directly for facts (rules, dates, official results), not blended |
| 2 — Original pollsters | PCPSR/PSR, AWRAD, other transparent-methodology institutions | Weighted per `docs/POLLING_METHOD.md` |
| 3 — Reputable news | Configurable Arabic/English outlets | Used for entity/event extraction only, never fed into vote-share numbers (section 17) |
| 4 — Other | Lower-confidence sources | Stored with low `VerificationConfidence`, never auto-overrides a higher-tier fact |

`Source.tier` (`services/api/app/models/enums.py::SourceTier`) encodes
this. Nothing in the codebase currently auto-derives tier from arbitrary
new sources — an administrator assigns it when the source is registered
(`SourceRegistry` is the `sources` table plus the admin flow described in
section 27, not yet built as a dedicated admin UI in this build — see
"What's not built yet" in the README).

## Source adapter contract

`services/ingestion/ingestion/sources/base.py::SourceAdapter` — every
adapter declares `ingestion_method` (`rss | api | licensed_api |
admin_entered | pdf_import`) and `respects_licensing: bool`.
`pipeline.py::run_pipeline` refuses to call `fetch()` on any adapter where
`respects_licensing` is not `True`. One reference adapter is implemented:
`rss_adapter.py::RssSourceAdapter` (uses `feedparser`, an optional
dependency not imported at module load).

## What this build does NOT include

- No adapters for any specific commercial/licensed news API — those
  require a paid license and API key; see `docs/SOURCE_LICENSING.md`.
- No PDF-import adapter implementation (interface only).
- No admin UI for registering/reviewing sources — the `sources` table and
  `AuditLog` model exist; the review workflow (section 27) is not built
  as screens in this pass.
