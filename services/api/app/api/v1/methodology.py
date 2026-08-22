from __future__ import annotations

from fastapi import APIRouter

from ...config import settings
from ...schemas.forecast import ModelPerformanceOut

router = APIRouter(tags=["methodology"])


@router.get("/methodology")
def get_methodology() -> dict:
    """Machine-readable methodology summary backing the in-app
    Methodology screen (section 30). Full prose lives in
    docs/FORECAST_MODEL.md / docs/POLLING_METHOD.md / docs/COALITION_MODEL.md
    — this endpoint returns pointers plus the headline parameters so the
    client can render "why this number" without hard-coding them."""
    return {
        "product_name": settings.product_name,
        "polling_average": {
            "summary": "Weighted average of polls asking the same "
            "'if elections were held today' vote-choice question. Weight = "
            "recency x sample-size x population-type x pollster quality. "
            "Never naive arithmetic averaging; never mixes differently "
            "worded questions.",
            "docs": "docs/POLLING_METHOD.md",
        },
        "forecast_model": {
            "summary": "Dirichlet Monte Carlo over the polling average, "
            "incorporating house-effect and turnout noise, configurable "
            "undecided-voter allocation, and staleness-driven uncertainty "
            "widening. Full Bayesian dynamic state-space latent-support "
            "model (spec Model B) is architected but not yet implemented — "
            "see docs/FORECAST_MODEL.md 'Current limitations'.",
            "docs": "docs/FORECAST_MODEL.md",
        },
        "seat_allocation": {
            "summary": "Sainte-Lague highest-averages method, versioned "
            "ElectionRuleSet, 1% national threshold, 132 seats, majority "
            "threshold = floor(total_seats/2)+1 = 67.",
            "docs": "docs/ELECTORAL_RULES.md",
        },
        "coalition_model": {
            "summary": "Mathematical majority feasibility from Monte Carlo "
            "simulations (objective); political compatibility is a "
            "separate, evidence-sourced 'compatibility score', never "
            "presented as a calibrated probability.",
            "docs": "docs/COALITION_MODEL.md",
        },
    }


@router.get("/model-performance", response_model=list[ModelPerformanceOut])
def get_model_performance() -> list[ModelPerformanceOut]:
    """Backtesting results (sections 18, 41). Empty until a rolling-origin
    backtest has actually been run against real historical elections under
    the current (post-2026-amendment) electoral system — see
    docs/MODEL_VALIDATION.md. Returning a fabricated accuracy number would
    violate CRITICAL ACCURACY RULE #18."""
    return []
