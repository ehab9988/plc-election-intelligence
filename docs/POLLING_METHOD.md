# Polling Database & Weighting Methodology

## Schema

See `services/api/app/models/polling.py`. Key design decisions:

- **`PollQuestion` is separate from `Poll`.** A single poll can carry
  multiple questions; results are scoped to the specific question that
  produced them via `question_type`, so "which party do you support?" is
  never merged with "if elections were held today, which list would you
  vote for?" (spec section 11 — these are not equivalent and are never
  treated as such anywhere in the codebase, including the polling
  average, which filters strictly on `question_type == "vote_choice_if_today"`).
- **`PollGeographicResult` only has rows a pollster actually reported.**
  National polling numbers are never divided by population to fabricate a
  city/governorate-level estimate (spec section 32).
- Methodology fields (`mode`, `sampling_procedure`, `weighting_procedure`,
  `population`, `west_bank_sample_size` / `gaza_sample_size`) are stored
  even when partially missing, so the quality score (below) can flag
  missing transparency rather than guessing.

## Poll Quality / Weighting

`services/forecasting/forecasting/polling_average.py`. Weight is a
product of four independently-justifiable, purely methodological factors
— never adjusted for perceived political coverage or a pollster's
editorial stance:

| Factor | Formula | Rationale |
|---|---|---|
| Recency | `0.5 ^ (age_days / 21)` | Exponential half-life; a 3-week-old poll counts half as much as a fresh one. |
| Sample size | `max(sqrt(n / 1200), 0.3)` | Approximates standard-error scaling without letting one huge poll dominate outright. |
| Population type | `likely_voters × 1.15`, `registered_voters × 1.0`, `all_adults × 0.85` | Likely-voter screens are generally more predictive for turnout-sensitive elections. |
| Pollster quality | `0.5 + (quality_score/100)` → 0.5x–1.5x | From `PollsterRating.quality_score`, itself methodology-based (sample transparency, weighting transparency, probability sampling, historical error where available — see spec section 12). |

No poll is ever counted twice: `Poll` has a unique constraint on
`(pollster_id, fieldwork_start, fieldwork_end, election_id)`.

## Current limitation

`PollsterRating` is modeled in the schema but not yet populated by a
rating pipeline — `services/api/app/api/v1/polls.py` currently passes a
flat placeholder `pollster_quality_score=70.0` pending that pipeline
(clearly marked with a `# TODO` at the call site). This affects the
*relative* weighting between pollsters, not the recency/sample-size/
population-type factors, which are fully live.

## Test fixture

`scripts/seed_data.py` and `apps/flutter_client/lib/data/fixtures/demo_fixture.dart`
both encode the same PCPSR August 5–8, 2026 fixture described in spec
section 51 (Fatah 32%, Hamas/Change and Reform 29%, third parties combined
18%, undecided 21%, n≈1270, face-to-face, likely voters). This is
TEST/SEED data, explicitly labeled as such in both files, fieldwork-dated,
and intended to be replaced/supplemented by real ingested polls before any
production launch.
