"""Candidate seat probability, coalition majority probability, and
simulation summary statistics.

Direct port of packages/election_rules/lib/src/candidate_probability.dart —
keep in sync.
"""

from __future__ import annotations

import bisect
from dataclasses import dataclass


def candidate_seat_probability(rank: int, party_seat_simulations: list[int]) -> float:
    """Probability a closed-list candidate at `rank` (1-based) wins a seat.

    Under closed-list PR, a voter votes for the list, not the candidate.
    A candidate at `rank` wins a seat in a given simulation iff that
    list's simulated seat count in that iteration is >= rank. This is
    CRITICAL ACCURACY RULE #7's implementation: never derive this from a
    fabricated per-candidate vote share.
    """
    if rank < 1:
        raise ValueError("Candidate list rank must be >= 1")
    if not party_seat_simulations:
        return 0.0
    win_count = sum(1 for seats in party_seat_simulations if seats >= rank)
    return win_count / len(party_seat_simulations)


def candidate_seat_probabilities_for_list(
    list_size: int, party_seat_simulations: list[int]
) -> list[float]:
    """Probability per rank (index 0 = rank 1) for an entire list in one pass.

    Guarantees monotonicity: probability(rank) never increases as rank
    increases, satisfying the acceptance test that candidate #10 cannot
    have a lower probability than #11 on the same normal closed list.
    """
    if not party_seat_simulations:
        return [0.0] * list_size
    n = len(party_seat_simulations)
    sorted_sims = sorted(party_seat_simulations)
    result = []
    for i in range(list_size):
        rank = i + 1
        lo = bisect.bisect_left(sorted_sims, rank)
        count_at_least_rank = len(sorted_sims) - lo
        result.append(count_at_least_rank / n)
    return result


def majority_threshold(total_seats: int) -> int:
    """floor(total_seats / 2) + 1 — never hard-coded elsewhere."""
    return (total_seats // 2) + 1


def coalition_majority_probability(
    coalition_list_ids: set[str],
    simulations: list[dict[str, int]],
    total_seats: int,
) -> float:
    """Probability that the combined seats of coalition_list_ids meet or
    exceed the majority threshold, across Monte Carlo simulations.
    """
    if not simulations:
        return 0.0
    threshold = majority_threshold(total_seats)
    hits = 0
    for sim in simulations:
        combined = sum(sim.get(list_id, 0) for list_id in coalition_list_ids)
        if combined >= threshold:
            hits += 1
    return hits / len(simulations)


@dataclass(frozen=True)
class SimulationSummary:
    median: float
    mean: float
    low50: float
    high50: float
    low80: float
    high80: float
    low95: float
    high95: float

    @staticmethod
    def from_values(values: list[float]) -> "SimulationSummary":
        if not values:
            return SimulationSummary(0, 0, 0, 0, 0, 0, 0, 0)
        sorted_values = sorted(values)
        n = len(sorted_values)

        def pct(p: float) -> float:
            idx = min(max(round((n - 1) * p), 0), n - 1)
            return float(sorted_values[idx])

        mean = sum(sorted_values) / n
        return SimulationSummary(
            median=pct(0.5),
            mean=mean,
            low50=pct(0.25),
            high50=pct(0.75),
            low80=pct(0.10),
            high80=pct(0.90),
            low95=pct(0.025),
            high95=pct(0.975),
        )
