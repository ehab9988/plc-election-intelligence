# Forecast Model

## Terminology (do not conflate these)

- **Poll** — one survey result.
- **Polling Average** — a weighted statistical combination of polls asking
  the *same* question (see `docs/POLLING_METHOD.md`). Not a forecast.
- **Nowcast** — what voting intentions appear to be today.
- **Election-Day Forecast** — a probability distribution over election-day
  outcomes, produced by Monte Carlo simulation.
- **Seat Projection** — seats produced by applying the election-law model
  (`packages/election_rules_py`) to a simulated vote distribution.
- **Coalition Seat Probability** — probability that a set of lists jointly
  reaches the majority threshold, from simulation data.
- **Coalition Compatibility** — a separate, evidence-based, non-probabilistic
  assessment of whether parties are politically willing to cooperate.

## What is implemented today

`services/forecasting/forecasting/`:

1. **`polling_average.py`** (Model A) — weighted average of polls asking
   the same "if elections were held today" question. Weight =
   `recency(half-life 21 days) × sample-size(sqrt-scaled) × population-type
   × pollster-quality-score`. Never naive arithmetic averaging; never mixes
   differently-worded questions (`question_type` is part of the join key).

2. **`monte_carlo.py`** — a **single-stage Dirichlet Monte Carlo** applied
   to the polling average. Per iteration:
   - Draw simulated vote shares (including an explicit "undecided" bucket)
     from a Dirichlet distribution centered on the polling average, with
     concentration inversely widened by polling staleness
     (`days_since_last_quality_poll`, section 59).
   - Reallocate the undecided bucket using a configurable method
     (`proportional` | `historical_partisan` | `monte_carlo_break`).
   - Add independent Gaussian house-effect and turnout noise.
   - Convert to integer votes and run the exact, tested Sainte-Laguë
     allocator (`election_rules_py`) — every iteration allocates exactly
     `total_seats`.
   - Record per-list seats and vote share for that iteration.

3. **`candidate_forecast.py`** — derives candidate seat probability from
   list rank vs. the iteration-level seat counts (never a vote share).

4. **`coalition.py`** — majority feasibility from the same iteration data.

## What is explicitly NOT implemented (honesty over false precision)

The product specification describes three composed models: (A) polling
aggregation, (B) a **Bayesian dynamic state-space model** estimating
latent party support over time with pollster house effects as a formal
hierarchical parameter, and (C) an election-day simulation layer. This
build implements (A) and a simplified version of (C) directly on top of
(A). It does **not** implement the day-by-day latent-support time
evolution described for (B) — there is no PyMC state-space model in this
codebase yet.

This is a deliberate scope decision, not an oversight, and it is flagged
in three places so it can't be missed or silently assumed away:
- `services/forecasting/forecasting/monte_carlo.py` module docstring
- `services/api/app/api/v1/methodology.py` (`/methodology` endpoint, so
  the in-app Methodology screen states it too)
- Here.

`monte_carlo.py` defines a `LatentSupportModel` Protocol as the intended
extension point: a future PyMC-based implementation just needs to produce
`(mean_vote_share_per_list, concentration)` for a given `as_of` date, and
the rest of the pipeline (undecided allocation, noise, seat allocation,
candidate/coalition probability) is already written against that
interface.

## Uncertainty is never hidden

Every `ForecastPartyResult` carries `vote_share_low95/high95`,
`vote_share_low80/high80`, and `seats_low50/high50` through `low95/high95`
— see `packages/election_rules_py/election_rules_py/candidate_probability.py:SimulationSummary`.
The UI (`apps/flutter_client/lib/widgets/party_forecast_card.dart` /
`uncertainty_range.dart`) always renders a range, never a bare number.

## Reproducibility

Every `ForecastRun` row stores `model_version`, `dataset_version`,
`random_seed`, `simulations_performed`, and `configuration` (the exact
Monte Carlo parameters used). Given the same seed and inputs, `run_monte_carlo`
is deterministic (asserted by `services/forecasting/tests/test_monte_carlo.py::test_reproducible_with_same_seed`).
Forecast runs are immutable once created — re-running never mutates a
prior row (section 39); publishing a new run does not delete or rewrite
old ones.

## Backtesting

`docs/MODEL_VALIDATION.md` covers the backtesting framework contract. As
of this build, `/api/v1/model-performance` returns an empty list rather
than a fabricated accuracy number, because no rolling-origin backtest has
actually been run against real historical elections under the current
(post-2026-amendment) electoral system.
