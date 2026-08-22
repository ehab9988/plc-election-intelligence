"""OpenAI web-search-based estimation of how likely two parties are to
end up running on one shared electoral list. Writes a
`CoalitionFormationEstimate` row per party pair — a single language
model's synthesized guess, not a calibrated statistic. No human review
step, by explicit product decision (same tradeoff as poll_discovery.py
and party_discovery.py, applied here to a genuinely more speculative
kind of number).

This is deliberately kept a SEPARATE concept from CoalitionEvidence
(sourced, dated statements) and from the seat-forecast's mathematical
majority probability (real Monte Carlo simulation over polling data).
Mixing this into either of those would misrepresent a guess as either a
sourced fact or a calibrated statistic — every place this number is
shown must label it as an AI estimate.

Could not be exercised against a real OpenAI account in this development
sandbox — see openai_search_adapter.py's docstring for the same caveat
about verifying the exact API shape against current OpenAI docs.
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass
from datetime import UTC, datetime
from uuid import UUID

from app.models import CoalitionEvidence, CoalitionFormationEstimate, Party
from sqlalchemy import select
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)

DEFAULT_MODEL = "gpt-4o-mini"

_ESTIMATE_SCHEMA = {
    "type": "object",
    "properties": {
        "likelihood_pct": {
            "type": "number",
            "description": "Your best estimate, 0-100, of the likelihood these two run on one shared list.",
        },
        "reasoning": {
            "type": "string",
            "description": "A short (2-4 sentence) explanation citing what you found, or your reasoning if little is public.",
        },
    },
    "required": ["likelihood_pct", "reasoning"],
    "additionalProperties": False,
}

_SYSTEM_PROMPT = """\
You are a political analysis assistant for a Palestinian election \
intelligence platform. Use web search to research the relationship \
between the two named parties/political groups regarding the upcoming \
Palestinian Legislative Council election, then give your own best \
numeric estimate (0-100) of how likely they are to end up running on \
ONE shared electoral list together. This is explicitly your own \
synthesized judgment, not a report of a number someone else published — \
say so in your reasoning, and cite what you found that informed it. Be \
willing to give a low number (parties often do NOT merge lists even \
after alliance talk) as well as a high one.
"""


@dataclass
class OpenAiCoalitionLikelihood:
    api_key: str | None = None
    model: str = DEFAULT_MODEL

    def __post_init__(self) -> None:
        import openai  # local import: optional dependency, not required unless this is used

        self._openai = openai
        self._client = openai.OpenAI(api_key=self.api_key) if self.api_key else openai.OpenAI()

    def estimate(self, party_a_name: str, party_b_name: str) -> dict | None:
        try:
            response = self._client.responses.create(
                model=self.model,
                tools=[{"type": "web_search"}],
                input=[
                    {"role": "system", "content": _SYSTEM_PROMPT},
                    {"role": "user", "content": f"Parties: {party_a_name} and {party_b_name}."},
                ],
                text={
                    "format": {
                        "type": "json_schema",
                        "name": "coalition_likelihood_estimate",
                        "schema": _ESTIMATE_SCHEMA,
                        "strict": True,
                    }
                },
            )
        except Exception:
            logger.exception("OpenAI coalition-likelihood estimate failed for %s / %s.", party_a_name, party_b_name)
            return None
        try:
            return json.loads(response.output_text)
        except (AttributeError, json.JSONDecodeError):
            logger.error("OpenAI coalition-likelihood: could not parse structured output.")
            return None


def _candidate_pairs(db: Session) -> set[tuple[UUID, UUID]]:
    """Every party pair with at least one CoalitionEvidence row — the
    same pairs the app already shows evidence for, so an estimate has
    something to sit alongside rather than appearing out of nowhere."""
    rows = db.execute(select(CoalitionEvidence.party_a_id, CoalitionEvidence.party_b_id)).all()
    return {(a, b) for a, b in rows}


def estimate_formation_likelihoods_via_ai(db: Session, api_key: str | None, model: str = DEFAULT_MODEL) -> dict:
    stats = {"candidate_pairs": 0, "estimated": 0, "skipped_no_names": 0, "skipped_api_error": 0}
    estimator = OpenAiCoalitionLikelihood(api_key=api_key, model=model)

    for party_a_id, party_b_id in _candidate_pairs(db):
        stats["candidate_pairs"] += 1
        party_a = db.get(Party, party_a_id)
        party_b = db.get(Party, party_b_id)
        if party_a is None or party_b is None:
            stats["skipped_no_names"] += 1
            continue

        result = estimator.estimate(party_a.name_en, party_b.name_en)
        if result is None:
            stats["skipped_api_error"] += 1
            continue

        likelihood = max(0.0, min(100.0, float(result.get("likelihood_pct", 0))))
        db.add(
            CoalitionFormationEstimate(
                party_a_id=party_a_id,
                party_b_id=party_b_id,
                likelihood_pct=likelihood,
                reasoning=str(result.get("reasoning", "")),
                model=model,
                generated_at=datetime.now(UTC),
            )
        )
        stats["estimated"] += 1

    db.commit()
    return stats
