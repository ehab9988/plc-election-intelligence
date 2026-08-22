# Coalition Model

Three deliberately separate concepts — never merged into one number:

## A. Mathematical coalition feasibility

"Given the forecast's simulated outcomes, what fraction of iterations had
`sum(seats for lists in coalition) >= majority_threshold`?" This is
objective and computed directly from simulation data:
`election_rules_py.coalition_majority_probability` /
`election_rules.coalitionMajorityProbability` (both tested).

Server-side (`services/api/app/api/v1/coalitions.py::simulate_coalition_endpoint`),
this is currently computed from **stored per-list seat histograms**
(`ForecastDistribution.histogram`), not the raw per-iteration simulation
sample. **This is a known limitation**: summing independent per-list
distributions loses the cross-list correlation that exists in the actual
joint simulation (if list A does unusually well in iteration *i*, list B
in the same coalition scenario is not independent of that). The
approximation is documented inline in the endpoint and produces a
reasonable estimate for the vertical slice, but a production deployment
should instead persist a compact sample of full per-iteration seat maps
per `ForecastRun` (e.g. a few thousand rows) so `/coalitions/simulate` can
compute the joint probability directly, the way
`forecasting/coalition.py::simulate_coalition` already does when given the
in-memory `ForecastOutput.raw_seat_simulations` (used by
`scripts/seed_data.py`'s single-run path and by the forecasting package's
own tests).

## B. Political coalition compatibility

Never a fabricated "probability of coalition formation." Stored as
`CoalitionEvidence` rows: `evidence_type` (`supporting` | `conflicting`),
a sourced `statement_summary`, and a `confidence` level — an evidence
graph, not a model output. The Coalition Lab UI shows this evidence
alongside (never combined with) the mathematical feasibility number.

If a future calibrated coalition-formation model is built from sufficient
historical data, it should be exposed as a distinctly-labeled
"coalition formation probability" field, not silently substituted for
`CoalitionEvidence` — see spec section 22's explicit instruction to call
it a "compatibility score" absent a calibrated methodology. Category C
below is NOT that model — it is explicitly an interim, uncalibrated
stand-in the product owner chose to add ahead of one existing (see that
section for the honest tradeoff).

## C. AI-estimated coalition-formation likelihood

Added later, and different in kind from A and B — not a third way of
computing the same objective feasibility number, and not another sourced
evidence row. `CoalitionFormationEstimate`
(`services/ingestion/ingestion/coalition_likelihood.py`) asks an LLM,
with web search, for its own numeric guess (0-100) at how likely two
parties are to end up on one shared list, run automatically with no
human review step (an explicit product decision — see
`poll_discovery.py`'s module docstring for the fuller reasoning, applied
here to a still-more-speculative kind of claim). It is a single model's
synthesis, not a calibrated statistic — there is no backtested
methodology behind the number the way there is behind the seat forecast.

Every place this is shown must label it as an AI estimate and must never
render it next to the mathematical feasibility percentage in a way that
could read as the same kind of number (see
`CoalitionFormationEstimate`'s and the Flutter
`CoalitionFormationEstimate` model's doc comments). This is the
calibrated-methodology gap the paragraph above warns against — closing
it honestly requires backtesting against real historical outcomes, which
this build does not have.

## Auto-generated scenarios

`forecasting/coalition.py::smallest_majority_coalition` is a **greedy
heuristic** (rank lists by median seats, take the smallest prefix that
crosses the majority threshold), not an exhaustive combinatorial search
over all subsets. Documented as such in its docstring — it is a
reasonable default for the "smallest majority coalition" auto-scenario
(spec section 23) but should not be presented as *the* smallest possible
majority coalition without a full search for elections with many lists.
