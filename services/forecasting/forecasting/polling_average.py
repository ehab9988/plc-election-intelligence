"""Model A: transparent weighted polling average (section 13).

Avoids naive arithmetic averaging. Weight is a product of independently
justifiable factors so the methodology page (section 30 "Methodology") can
show its work rather than asserting a black box.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from datetime import date


@dataclass
class PollObservation:
    """One (poll, list) data point feeding the average. `pct` is the
    normalized share of the specific "if elections were held today, which
    list" question — never mixed with a differently-worded question
    (section 11)."""

    poll_id: str
    pollster_id: str
    electoral_list_id: str
    pct: float
    sample_size: int
    fieldwork_end: date
    population: str  # all_adults | registered_voters | likely_voters
    pollster_quality_score: float  # 0-100, from PollsterRating, methodology-based only


@dataclass
class WeightingConfig:
    recency_half_life_days: float = 21.0
    min_sample_weight: float = 0.3  # weight floor so very small samples aren't zeroed out
    reference_sample_size: int = 1200
    likely_voter_bonus: float = 1.15
    registered_voter_bonus: float = 1.0
    all_adults_penalty: float = 0.85


def recency_weight(fieldwork_end: date, as_of: date, half_life_days: float) -> float:
    age_days = max((as_of - fieldwork_end).days, 0)
    return 0.5 ** (age_days / half_life_days)


def sample_size_weight(sample_size: int, reference: int, floor: float) -> float:
    # sqrt(n) scaling approximates standard-error-based weighting without
    # letting one huge poll dominate the average outright.
    raw = math.sqrt(max(sample_size, 1) / reference)
    return max(raw, floor)


def population_weight(population: str, cfg: WeightingConfig) -> float:
    return {
        "likely_voters": cfg.likely_voter_bonus,
        "registered_voters": cfg.registered_voter_bonus,
        "all_adults": cfg.all_adults_penalty,
    }.get(population, cfg.registered_voter_bonus)


def pollster_quality_weight(quality_score: float) -> float:
    # Map 0-100 quality score to a 0.5x-1.5x multiplier, methodology-based.
    return 0.5 + (max(min(quality_score, 100.0), 0.0) / 100.0)


@dataclass
class ListAverage:
    electoral_list_id: str
    weighted_average_pct: float
    trend_low: float
    trend_high: float
    n_polls_used: int
    most_recent_fieldwork_end: date | None


def compute_polling_average(
    observations: list[PollObservation],
    as_of: date,
    cfg: WeightingConfig | None = None,
) -> dict[str, ListAverage]:
    """Returns one ListAverage per electoral_list_id.

    `trend_low`/`trend_high` is a simple weighted-spread band (not a
    credible interval — the Monte Carlo forecast is where calibrated
    uncertainty intervals live). This is intentionally a separate,
    simpler "polls-only" view per section 13.
    """
    cfg = cfg or WeightingConfig()
    by_list: dict[str, list[tuple[float, float]]] = {}  # list_id -> [(pct, weight)]
    most_recent: dict[str, date] = {}

    for obs in observations:
        w = (
            recency_weight(obs.fieldwork_end, as_of, cfg.recency_half_life_days)
            * sample_size_weight(obs.sample_size, cfg.reference_sample_size, cfg.min_sample_weight)
            * population_weight(obs.population, cfg)
            * pollster_quality_weight(obs.pollster_quality_score)
        )
        by_list.setdefault(obs.electoral_list_id, []).append((obs.pct, w))
        if obs.electoral_list_id not in most_recent or obs.fieldwork_end > most_recent[obs.electoral_list_id]:
            most_recent[obs.electoral_list_id] = obs.fieldwork_end

    results: dict[str, ListAverage] = {}
    for list_id, pairs in by_list.items():
        total_w = sum(w for _, w in pairs)
        if total_w <= 0:
            continue
        weighted_avg = sum(pct * w for pct, w in pairs) / total_w
        # Weighted spread as a simple dispersion indicator.
        variance = sum(w * (pct - weighted_avg) ** 2 for pct, w in pairs) / total_w
        spread = math.sqrt(variance) if len(pairs) > 1 else 2.0
        results[list_id] = ListAverage(
            electoral_list_id=list_id,
            weighted_average_pct=round(weighted_avg, 2),
            trend_low=round(max(weighted_avg - spread, 0.0), 2),
            trend_high=round(min(weighted_avg + spread, 100.0), 2),
            n_polls_used=len(pairs),
            most_recent_fieldwork_end=most_recent.get(list_id),
        )
    return results
