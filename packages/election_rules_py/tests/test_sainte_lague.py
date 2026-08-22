"""Mirrors packages/election_rules/test/sainte_lague_test.dart.

NOTE: this repository's development sandbox has no working Python runtime
(only a Windows Store execution-alias stub), so these tests could not be
executed here. The identical logic in Dart (see the sibling package) WAS
executed via `dart test` and passed 24/24. Run these with
`pip install -e .[dev] && pytest` in any environment with real Python
before relying on this module in production — see docs/MODEL_VALIDATION.md.
"""

from datetime import UTC, datetime

import pytest
from election_rules_py import (
    AllocationMethod,
    ElectionRuleSet,
    allocate_seats_sainte_lague,
    majority_threshold,
)


def make_rules(total_seats=132, threshold=0.01, method=AllocationMethod.SAINTE_LAGUE):
    return ElectionRuleSet(
        id="test-ruleset",
        election_id="test-election",
        version="1.0.0",
        effective_from=datetime(2026, 1, 1, tzinfo=UTC),
        electoral_system="Nationwide closed-list proportional representation",
        district_structure="Single national constituency",
        total_seats=total_seats,
        threshold_fraction=threshold,
        allocation_method=method,
        minimum_candidate_age=23,
        source_document="test fixture",
        verified_at=datetime(2026, 1, 1, tzinfo=UTC),
    )


def test_golden_hand_verified_example():
    result = allocate_seats_sainte_lague(
        {"A": 100000, "B": 80000, "C": 30000},
        make_rules(total_seats=7, threshold=0.0),
    )
    assert result.seats_by_list == {"A": 3, "B": 3, "C": 1}
    assert result.total_seats_allocated == 7
    assert result.tie_occurred is False


def test_every_allocation_sums_to_132():
    result = allocate_seats_sainte_lague(
        {"A": 318000, "B": 296000, "C": 95000, "D": 85000, "E": 60000, "F": 46000},
        make_rules(),
    )
    assert sum(result.seats_by_list.values()) == 132
    assert result.total_seats_allocated == 132


def test_party_exactly_at_threshold_is_included():
    votes = {"A": 500000, "B": 400000, "C": 90000, "D": 10000}
    result = allocate_seats_sainte_lague(votes, make_rules())
    assert "D" not in result.below_threshold


def test_party_just_below_threshold_excluded():
    votes = {"A": 500000, "B": 400000, "C": 90999, "D": 9001}
    result = allocate_seats_sainte_lague(votes, make_rules())
    assert "D" in result.below_threshold
    assert result.seats_by_list["D"] == 0


def test_party_just_above_threshold_included():
    votes = {"A": 500000, "B": 400000, "C": 89999, "D": 10001}
    result = allocate_seats_sainte_lague(votes, make_rules())
    assert "D" not in result.below_threshold


def test_zero_vote_party_gets_zero_seats():
    votes = {"A": 500000, "B": 400000, "C": 100000, "D": 0}
    result = allocate_seats_sainte_lague(votes, make_rules())
    assert result.seats_by_list["D"] == 0
    assert "D" in result.below_threshold


def test_all_zero_votes_no_throw():
    result = allocate_seats_sainte_lague({"A": 0, "B": 0}, make_rules())
    assert result.total_seats_allocated == 0


def test_majority_threshold_132_is_67():
    assert majority_threshold(132) == 67
    assert make_rules().majority_threshold == 67


def test_majority_threshold_odd_totals():
    assert majority_threshold(101) == 51
    assert majority_threshold(1) == 1


def test_unsupported_method_raises():
    with pytest.raises(NotImplementedError):
        allocate_seats_sainte_lague({"A": 100}, make_rules(method=AllocationMethod.D_HONDT))


def test_deterministic_reproducibility():
    votes = {"A": 318000, "B": 296000, "C": 95000, "D": 85000, "E": 60000, "F": 46000}
    r1 = allocate_seats_sainte_lague(votes, make_rules())
    r2 = allocate_seats_sainte_lague(votes, make_rules())
    assert r1.seats_by_list == r2.seats_by_list
