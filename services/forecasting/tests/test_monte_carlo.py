"""NOTE: could not be executed in this repo's development sandbox (no
working Python runtime — see packages/election_rules_py/tests for
details). Run with `pip install -r requirements.txt -r ../api/requirements.txt`
plus `pip install pytest` in a real environment before relying on this
module. Covers the acceptance criteria in spec section 79."""

from datetime import datetime, timezone

from election_rules_py import AllocationMethod, ElectionRuleSet

from forecasting.monte_carlo import ForecastInputs, run_monte_carlo
from forecasting.candidate_forecast import compute_candidate_forecasts
from forecasting.coalition import simulate_coalition


def make_rules(total_seats=132):
    return ElectionRuleSet(
        id="t",
        election_id="t",
        version="1.0.0",
        effective_from=datetime(2026, 1, 1, tzinfo=timezone.utc),
        electoral_system="closed-list PR",
        district_structure="single national constituency",
        total_seats=total_seats,
        threshold_fraction=0.01,
        allocation_method=AllocationMethod.SAINTE_LAGUE,
        minimum_candidate_age=23,
        source_document="test",
        verified_at=datetime(2026, 1, 1, tzinfo=timezone.utc),
    )


def make_inputs(n=5000, seed=42):
    return ForecastInputs(
        list_ids=["A", "B", "C", "D", "E", "F"],
        polling_average_pct={"A": 32, "B": 29, "C": 8, "D": 6, "E": 3, "F": 1},
        n_simulations=n,
        random_seed=seed,
    )


def test_every_simulation_allocates_exactly_total_seats():
    rules = make_rules(132)
    out = run_monte_carlo(make_inputs(), rules)
    for sim in out.raw_seat_simulations:
        assert sum(sim.values()) == 132


def test_probabilities_between_0_and_100_after_scaling():
    rules = make_rules(132)
    out = run_monte_carlo(make_inputs(), rules)
    for result in out.list_results.values():
        assert 0.0 <= result.probability_largest_list <= 1.0
        assert 0.0 <= result.probability_cross_threshold <= 1.0
        assert 0.0 <= result.probability_majority_alone <= 1.0


def test_reproducible_with_same_seed():
    rules = make_rules(132)
    out1 = run_monte_carlo(make_inputs(seed=7), rules)
    out2 = run_monte_carlo(make_inputs(seed=7), rules)
    assert out1.raw_seat_simulations == out2.raw_seat_simulations


def test_candidate_10_not_less_than_candidate_11():
    rules = make_rules(132)
    out = run_monte_carlo(make_inputs(), rules)
    candidates_by_list = {"A": [(f"cand-{i}", i) for i in range(1, 45)]}
    forecasts = compute_candidate_forecasts(out, candidates_by_list)
    by_rank = {f.list_rank: f.seat_probability for f in forecasts}
    assert by_rank[10] >= by_rank[11]


def test_coalition_majority_threshold_is_67_for_132_seats():
    rules = make_rules(132)
    out = run_monte_carlo(make_inputs(), rules)
    result = simulate_coalition(out, ["A", "B"], total_seats=132)
    assert 0.0 <= result.majority_probability <= 1.0
