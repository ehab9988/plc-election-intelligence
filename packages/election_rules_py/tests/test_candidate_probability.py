"""Mirrors packages/election_rules/test/candidate_probability_test.dart.
See test_sainte_lague.py for a note on why these could not be executed
in this repo's development sandbox.
"""

import pytest

from election_rules_py import (
    SimulationSummary,
    candidate_seat_probabilities_for_list,
    candidate_seat_probability,
    coalition_majority_probability,
)


def test_probabilities_within_0_1():
    sims = [i % 30 for i in range(1000)]
    for rank in range(1, 41):
        p = candidate_seat_probability(rank, sims)
        assert 0.0 <= p <= 1.0


def test_monotonic_non_increasing():
    sims = [5, 10, 15, 20, 3, 8, 12, 30, 1, 0]
    probs = candidate_seat_probabilities_for_list(35, sims)
    for i in range(1, len(probs)):
        assert probs[i] <= probs[i - 1]


def test_rank10_not_less_than_rank11():
    sims = [(i * 37) % 25 for i in range(5000)]
    probs = candidate_seat_probabilities_for_list(25, sims)
    assert probs[9] >= probs[10]


def test_rank_exceeding_max_is_zero():
    assert candidate_seat_probability(20, [1, 2, 3, 2, 1]) == 0.0


def test_rank_always_achievable_is_one():
    assert candidate_seat_probability(5, [10, 12, 15, 20]) == 1.0


def test_empty_simulations_returns_zero():
    assert candidate_seat_probability(1, []) == 0.0


def test_rank_below_1_raises():
    with pytest.raises(ValueError):
        candidate_seat_probability(0, [1, 2])


def test_coalition_majority_probability_matches_data():
    sims = [
        {"A": 40, "B": 30, "C": 62},
        {"A": 35, "B": 35, "C": 62},
        {"A": 30, "B": 30, "C": 72},
        {"A": 20, "B": 20, "C": 92},
    ]
    p = coalition_majority_probability({"A", "B"}, sims, 132)
    assert p == 0.5


def test_coalition_missing_list_treated_as_zero():
    sims = [{"A": 67}, {"B": 100}]
    p = coalition_majority_probability({"A"}, sims, 132)
    assert p == 0.5


def test_simulation_summary_ordering():
    values = [float(i) for i in range(1000)]
    summary = SimulationSummary.from_values(values)
    assert (
        summary.low95
        <= summary.low80
        <= summary.low50
        <= summary.median
        <= summary.high50
        <= summary.high80
        <= summary.high95
    )


def test_simulation_summary_empty():
    summary = SimulationSummary.from_values([])
    assert summary.median == 0
