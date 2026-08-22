# Source Licensing

This product may be sold commercially, so ingestion must not rely on
scraping that violates a site's terms of service or copyright.

## Rules enforced in code

- `SourceAdapter.respects_licensing` must be `True` before
  `pipeline.run_pipeline` will call it (`services/ingestion/ingestion/pipeline.py`).
- `Article` (the news storage model) has no field for full article text —
  only `permitted_snippet` (short, fair-use-scoped), `headline`, `author`,
  `published_at`, `canonical_url`, and an optional `app_generated_summary`.
  There is no code path in this repository that stores a complete
  copyrighted article body.
- `image_url` is stored as a reference only when licensing permits use;
  nothing in this build re-hosts images.

## Before enabling a new source in production

1. Confirm the source's terms of service and `robots.txt` permit the
   planned `ingestion_method`.
2. For `licensed_api`, obtain the license/API key and store it via
   environment variables (see `.env.example`) — never commit it.
3. Register the source with the correct `tier` and `license_notes`
   (`sources` table).
4. If in doubt about a specific source, default to RSS (`rss_adapter.py`)
   or admin-entered content, both of which carry the lowest licensing
   risk.

## Licensed/commercial providers this build does not include

- No commercial news API integration is wired up (would need a
  contracted provider and paid credentials).
- No PCPSR/AWRAD API integration — the August 2026 fixture in
  `scripts/seed_data.py` / the Flutter demo fixture is manually
  transcribed from the publicly reported topline figures as TEST/SEED
  data (section 51), not pulled via any pollster API, because no such
  public API is assumed to exist.
