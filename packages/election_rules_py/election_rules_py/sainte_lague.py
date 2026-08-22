"""Sainte-Lague highest-averages seat allocation.

Direct port of packages/election_rules/lib/src/sainte_lague.dart — keep in
sync; that Dart version is the one covered by `dart test` in this repo's
sandbox.
"""

from __future__ import annotations

from dataclasses import dataclass

from .rule_set import AllocationMethod, ElectionRuleSet


@dataclass(frozen=True)
class SeatAllocationResult:
    seats_by_list: dict[str, int]
    below_threshold: set[str]
    tie_occurred: bool
    total_seats_allocated: int


def _standard_divisor(seats_won_so_far: int) -> float:
    return float(2 * seats_won_so_far + 1)


def _modified_divisor(seats_won_so_far: int) -> float:
    return 1.4 if seats_won_so_far == 0 else _standard_divisor(seats_won_so_far)


def allocate_seats_sainte_lague(
    votes_by_list: dict[str, int],
    rules: ElectionRuleSet,
) -> SeatAllocationResult:
    """Allocate rules.general_pool_seats seats across votes_by_list.

    Pure and deterministic: same inputs always produce the same result,
    which forecast reproducibility depends on (a Monte Carlo run calls
    this tens of thousands of times).

    Lists whose vote share is strictly below rules.threshold_fraction are
    excluded from allocation (zero seats) but still count toward total
    valid votes when computing shares.
    """
    if rules.allocation_method not in (
        AllocationMethod.SAINTE_LAGUE,
        AllocationMethod.MODIFIED_SAINTE_LAGUE,
    ):
        raise NotImplementedError(
            f"allocate_seats_sainte_lague only supports sainte_lague/"
            f"modified_sainte_lague; rule set {rules.id} specifies "
            f"{rules.allocation_method}."
        )

    divisor_fn = (
        _modified_divisor
        if rules.allocation_method == AllocationMethod.MODIFIED_SAINTE_LAGUE
        else _standard_divisor
    )

    total_votes = sum(votes_by_list.values())
    seats: dict[str, int] = {list_id: 0 for list_id in votes_by_list}
    below_threshold: set[str] = set()

    if total_votes <= 0:
        return SeatAllocationResult(
            seats_by_list=seats,
            below_threshold=set(votes_by_list.keys()),
            tie_occurred=False,
            total_seats_allocated=0,
        )

    eligible: list[str] = []
    for list_id, votes in votes_by_list.items():
        share = votes / total_votes
        if share < rules.threshold_fraction:
            below_threshold.add(list_id)
        else:
            eligible.append(list_id)

    seats_to_allocate = rules.general_pool_seats
    tie_occurred = False

    for _ in range(seats_to_allocate):
        if not eligible:
            break

        winner: str | None = None
        best_quotient = -1.0
        tied_this_round = False

        for list_id in sorted(eligible):
            quotient = votes_by_list[list_id] / divisor_fn(seats[list_id])
            if quotient > best_quotient:
                best_quotient = quotient
                winner = list_id
                tied_this_round = False
            elif quotient == best_quotient:
                tied_this_round = True

        if tied_this_round:
            tie_occurred = True
        assert winner is not None
        seats[winner] += 1

    allocated = sum(seats.values())

    return SeatAllocationResult(
        seats_by_list=seats,
        below_threshold=below_threshold,
        tie_occurred=tie_occurred,
        total_seats_allocated=allocated,
    )
