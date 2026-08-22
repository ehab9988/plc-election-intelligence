"""Derives candidate seat probabilities from a completed Monte Carlo run.

Never computes an individual candidate vote share (CRITICAL ACCURACY RULE
#7) — probability is purely a function of list rank vs. that list's
simulated seat counts.
"""

from __future__ import annotations

from dataclasses import dataclass

from election_rules_py import candidate_seat_probabilities_for_list

from .monte_carlo import ForecastOutput


@dataclass
class CandidateForecast:
    candidate_id: str
    electoral_list_id: str
    list_rank: int
    seat_probability: float


def compute_candidate_forecasts(
    output: ForecastOutput,
    candidates_by_list: dict[str, list[tuple[str, int]]],  # list_id -> [(candidate_id, rank), ...]
) -> list[CandidateForecast]:
    forecasts: list[CandidateForecast] = []
    for list_id, candidates in candidates_by_list.items():
        if not candidates:
            continue
        max_rank = max(rank for _, rank in candidates)
        party_seat_sims = [sim.get(list_id, 0) for sim in output.raw_seat_simulations]
        probs_by_rank = candidate_seat_probabilities_for_list(max_rank, party_seat_sims)
        for candidate_id, rank in candidates:
            forecasts.append(
                CandidateForecast(
                    candidate_id=candidate_id,
                    electoral_list_id=list_id,
                    list_rank=rank,
                    seat_probability=round(probs_by_rank[rank - 1], 4),
                )
            )
    return forecasts
