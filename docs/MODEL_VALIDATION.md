# Model Validation

## Contract

Accuracy claims must be measurable, not asserted (CRITICAL ACCURACY RULE
#18). `GET /api/v1/model-performance` returns `ModelPerformanceOut[]`
(`services/api/app/schemas/forecast.py`): `model_version`,
`evaluation_period_start/end`, `mean_absolute_error_vote_share`,
`brier_score`, `interval_coverage_80pct`, `notes`.

## Current state: empty, on purpose

The endpoint returns `[]` today
(`services/api/app/api/v1/methodology.py::get_model_performance`). No
rolling-origin backtest has been run against real historical Palestinian
elections under the current (post-2026-amendment) electoral system in
this build — the 2006 mixed-system election is not statistically
comparable to the current full-PR system (spec section 18), and no other
election has occurred under the current rules yet to backtest against.
Returning a fabricated MAE/Brier score would violate the project's core
accuracy principle. This will remain empty until a real backtest is
implemented and run.

## How to add a real backtest

1. Collect historical polls + results for elections held under a
   comparable electoral system (once available).
2. Rolling-origin split: for each historical date `t`, run the forecast
   engine using only polls with `fieldwork_end <= t`, compare the
   resulting distribution to the actual outcome.
3. Compute MAE (vote share), Brier score (largest-list / majority
   probability calibration), and 80%-interval coverage (fraction of
   elections where the true outcome fell inside the reported 80% range —
   should be close to 80%, not higher or lower).
4. Never trains on future information relative to `t` — the whole point
   of the rolling-origin design.
5. Persist results as rows returned by `/model-performance`; do not hand
   -write a number into the endpoint.

## What IS verified in this build

Not model *accuracy* (impossible to claim without real backtesting data),
but model *correctness*: the Sainte-Laguë allocator, threshold handling,
majority-threshold formula, and candidate-probability monotonicity are
covered by 24 passing tests in `packages/election_rules` (`dart test`),
mirrored (but not executed, see README) in
`packages/election_rules_py/tests/`. Reproducibility of the Monte Carlo
engine given a fixed seed is asserted in
`services/forecasting/tests/test_monte_carlo.py` (written, not executed —
no Python runtime in this build's sandbox).
