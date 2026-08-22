"""Election-day Monte Carlo simulation engine.

IMPLEMENTATION NOTE (honesty over false precision, see docs/FORECAST_MODEL.md):
this module implements Model A (polling average, see polling_average.py)
composed with a single-stage Dirichlet Monte Carlo standing in for the
combination of Model B (Bayesian dynamic state-space latent-support
estimate) and Model C (election-day simulation) described in the product
spec. It already incorporates: sampling/house-effect/turnout uncertainty,
configurable undecided-voter allocation, threshold application, exact
Sainte-Lague seat allocation, and staleness-driven uncertainty inflation.
It deliberately does NOT implement day-by-day latent-support time
evolution (a full PyMC state-space model) — that is a documented extension
point (`LatentSupportModel` protocol below) rather than something asserted
as already built. Never remove this note without actually implementing the
time-evolution layer and re-validating against docs/MODEL_VALIDATION.md.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Protocol

import numpy as np

from election_rules_py import (
    ElectionRuleSet,
    SimulationSummary,
    allocate_seats_sainte_lague,
    candidate_seat_probabilities_for_list,
    coalition_majority_probability,
    majority_threshold,
)

VOTE_SCALE = 1_000_000  # arbitrary consistent scale so Sainte-Lague sees integer votes


class LatentSupportModel(Protocol):
    """Extension point for a future Bayesian dynamic state-space model
    (spec Model B). Must return, for the requested `as_of` date, a mean
    vote-share estimate and an uncertainty (concentration) per list so the
    Monte Carlo layer below can consume it without caring how it was
    derived (polling average vs. full state-space posterior)."""

    def latent_support(self, as_of) -> tuple[dict[str, float], float]: ...


@dataclass
class ForecastInputs:
    list_ids: list[str]
    polling_average_pct: dict[str, float]  # need not sum to 100; remainder treated as undecided
    n_simulations: int
    random_seed: int

    # Uncertainty knobs — see docs/FORECAST_MODEL.md for justification.
    # Higher concentration => tighter distribution around the mean.
    dirichlet_concentration: float = 40.0
    house_effect_std_pct: float = 1.5
    turnout_noise_std_pct: float = 1.0

    undecided_allocation: str = "proportional"  # proportional|historical_partisan|monte_carlo_break
    historical_partisan_weights: dict[str, float] | None = None

    # Staleness: days since the most recent high-quality poll. Widens
    # uncertainty rather than pretending old data is still precise
    # (section 59).
    days_since_last_quality_poll: int = 0
    staleness_widen_per_30_days: float = 0.15  # fractional widening of std per 30 stale days


@dataclass
class ListSimulationResult:
    electoral_list_id: str
    vote_share_summary: SimulationSummary
    seats_summary: SimulationSummary
    probability_largest_list: float
    probability_cross_threshold: float
    probability_majority_alone: float


@dataclass
class ForecastOutput:
    list_results: dict[str, ListSimulationResult]
    # raw per-iteration seat maps, kept in memory for candidate/coalition
    # probability calculations; callers should NOT persist all of this,
    # only the summarized ForecastDistribution histograms (section 39).
    raw_seat_simulations: list[dict[str, int]] = field(repr=False, default_factory=list)
    raw_vote_share_simulations: dict[str, list[float]] = field(repr=False, default_factory=dict)


def _effective_concentration(inputs: ForecastInputs) -> float:
    widen_factor = 1.0 + inputs.staleness_widen_per_30_days * (
        inputs.days_since_last_quality_poll / 30.0
    )
    # Wider uncertainty == LOWER Dirichlet concentration.
    return max(inputs.dirichlet_concentration / widen_factor, 2.0)


def run_monte_carlo(inputs: ForecastInputs, rules: ElectionRuleSet) -> ForecastOutput:
    rng = np.random.default_rng(inputs.random_seed)
    list_ids = inputs.list_ids
    k = len(list_ids)

    base_pct = np.array([max(inputs.polling_average_pct.get(lid, 0.0), 0.01) for lid in list_ids])
    undecided_pct = max(100.0 - base_pct.sum(), 0.0)
    categories_pct = np.append(base_pct, max(undecided_pct, 0.01))

    concentration = _effective_concentration(inputs)
    alpha = categories_pct * (concentration / 100.0)
    alpha = np.clip(alpha, 0.05, None)

    # (n_simulations, k+1) draws summing to 1 per row, including undecided.
    draws = rng.dirichlet(alpha, size=inputs.n_simulations)

    house_effects = rng.normal(0.0, inputs.house_effect_std_pct / 100.0, size=k)
    turnout_noise = rng.normal(0.0, inputs.turnout_noise_std_pct / 100.0, size=(inputs.n_simulations, k))

    party_shares = draws[:, :k]
    undecided_shares = draws[:, k]

    reallocated = _allocate_undecided(
        party_shares, undecided_shares, inputs.undecided_allocation,
        list_ids, inputs.historical_partisan_weights, rng,
    )

    adjusted = np.clip(reallocated + house_effects[None, :] + turnout_noise, 0.0, None)
    adjusted = adjusted / adjusted.sum(axis=1, keepdims=True)

    votes = np.round(adjusted * VOTE_SCALE).astype(int)

    raw_seat_sims: list[dict[str, int]] = []
    seats_matrix = np.zeros((inputs.n_simulations, k), dtype=int)
    below_threshold_counts = np.zeros(k, dtype=int)

    for i in range(inputs.n_simulations):
        votes_by_list = {list_ids[j]: int(votes[i, j]) for j in range(k)}
        result = allocate_seats_sainte_lague(votes_by_list, rules)
        raw_seat_sims.append(result.seats_by_list)
        for j, lid in enumerate(list_ids):
            seats_matrix[i, j] = result.seats_by_list.get(lid, 0)
            if lid in result.below_threshold:
                below_threshold_counts[j] += 1

    seats_per_sim_max = seats_matrix.max(axis=1)

    list_results: dict[str, ListSimulationResult] = {}
    raw_vote_share_sims: dict[str, list[float]] = {}
    threshold = majority_threshold(rules.total_seats)

    for j, lid in enumerate(list_ids):
        vote_share_pct_values = list((adjusted[:, j] * 100).tolist())
        raw_vote_share_sims[lid] = vote_share_pct_values
        seat_values = list(seats_matrix[:, j].tolist())

        prob_largest = float(np.mean(seats_matrix[:, j] == seats_per_sim_max))
        prob_cross_threshold = 1.0 - (below_threshold_counts[j] / inputs.n_simulations)
        prob_majority_alone = float(np.mean(seats_matrix[:, j] >= threshold))

        list_results[lid] = ListSimulationResult(
            electoral_list_id=lid,
            vote_share_summary=SimulationSummary.from_values(vote_share_pct_values),
            seats_summary=SimulationSummary.from_values(seat_values),
            probability_largest_list=round(prob_largest, 4),
            probability_cross_threshold=round(prob_cross_threshold, 4),
            probability_majority_alone=round(prob_majority_alone, 4),
        )

    return ForecastOutput(
        list_results=list_results,
        raw_seat_simulations=raw_seat_sims,
        raw_vote_share_simulations=raw_vote_share_sims,
    )


def _allocate_undecided(
    party_shares: np.ndarray,
    undecided_shares: np.ndarray,
    method: str,
    list_ids: list[str],
    historical_weights: dict[str, float] | None,
    rng: np.random.Generator,
) -> np.ndarray:
    n, k = party_shares.shape
    if method == "proportional":
        row_totals = party_shares.sum(axis=1, keepdims=True)
        row_totals = np.where(row_totals == 0, 1.0, row_totals)
        break_fractions = party_shares / row_totals
        return party_shares + undecided_shares[:, None] * break_fractions

    if method == "historical_partisan":
        weights = historical_weights or {lid: 1.0 / k for lid in list_ids}
        w = np.array([weights.get(lid, 0.0) for lid in list_ids])
        w = w / w.sum() if w.sum() > 0 else np.full(k, 1.0 / k)
        return party_shares + undecided_shares[:, None] * w[None, :]

    if method == "monte_carlo_break":
        alpha = np.clip(party_shares.mean(axis=0) * 20.0, 0.1, None)
        break_draws = rng.dirichlet(alpha, size=n)
        return party_shares + undecided_shares[:, None] * break_draws

    raise ValueError(f"Unknown undecided_allocation method: {method}")
