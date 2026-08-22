"""Coalition Lab math (sections 22-23): mathematical feasibility only —
political compatibility evidence is stored/served separately by the API
from CoalitionEvidence rows, never computed here."""

from __future__ import annotations

from dataclasses import dataclass

from election_rules_py import (
    SimulationSummary,
    coalition_majority_probability,
    majority_threshold,
)

from .monte_carlo import ForecastOutput


@dataclass
class CoalitionResult:
    electoral_list_ids: tuple[str, ...]
    seats_median: int
    seats_low80: int
    seats_high80: int
    majority_probability: float


def simulate_coalition(
    output: ForecastOutput, electoral_list_ids: list[str], total_seats: int
) -> CoalitionResult:
    combined_per_sim = [
        sum(sim.get(lid, 0) for lid in electoral_list_ids) for sim in output.raw_seat_simulations
    ]
    summary = SimulationSummary.from_values(combined_per_sim)
    prob = coalition_majority_probability(set(electoral_list_ids), output.raw_seat_simulations, total_seats)
    return CoalitionResult(
        electoral_list_ids=tuple(electoral_list_ids),
        seats_median=int(summary.median),
        seats_low80=int(summary.low80),
        seats_high80=int(summary.high80),
        majority_probability=round(prob, 4),
    )


def smallest_majority_coalition(
    output: ForecastOutput, list_ids: list[str], total_seats: int, max_members: int = 4
) -> CoalitionResult | None:
    """Greedy search over median seat counts for the smallest (fewest
    members, then fewest median seats) combination that crosses the
    majority threshold with a reasonable probability. A heuristic, not an
    exhaustive combinatorial search — documented as such in
    docs/COALITION_MODEL.md."""
    threshold = majority_threshold(total_seats)
    medians = {
        lid: SimulationSummary.from_values(
            [sim.get(lid, 0) for sim in output.raw_seat_simulations]
        ).median
        for lid in list_ids
    }
    ranked = sorted(list_ids, key=lambda lid: medians[lid], reverse=True)

    best: CoalitionResult | None = None
    for size in range(1, max_members + 1):
        combo = ranked[:size]
        result = simulate_coalition(output, combo, total_seats)
        if result.seats_median >= threshold:
            best = result
            break
    return best
