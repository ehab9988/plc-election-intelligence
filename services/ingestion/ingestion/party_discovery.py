"""OpenAI web-search-based party and electoral-list discovery. Finds
electoral lists (and the parties composing them) reported as running, or
credibly reported to be considering running, in the election, and drafts
them into the database for analyst review.

Never assigns a discovered list/party a RegistrationStatus stronger than
the "considering" family from AI alone — statuses that assert an
official outcome (submitted_registration, provisional,
officially_approved, rejected, withdrawn, disqualified) require a real
CEC citation, which a web-search summary is not (spec section 5: "never
mark a list officially_approved without a CEC citation"). Any hint
outside {rumored, considering, announced_intention} is clamped down to
rumored — the same defensive pattern poll_discovery.py uses for
verification, applied here to registration status instead.

A newly drafted list appears immediately on the Parties/Coalition Lab
screens, but NOT in the Forecast/Parliament seat projections until a
forecast actually runs with poll data covering it — an electoral list
with no polling data correctly shows ~0% support rather than a
fabricated share, and jobs.maybe_recompute_forecast() only re-runs on a
newly *verified* poll, not on a newly discovered list by itself. That is
intentional, not a bug: a list existing is not evidence of its support.

Could not be exercised against a real OpenAI account in this development
sandbox — see openai_search_adapter.py's docstring for the same caveat
about verifying the exact API shape against current OpenAI docs.
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass
from uuid import UUID

from app.models import ElectoralList, ElectoralListParty, Party
from app.models.enums import RegistrationStatus, VerificationConfidence
from sqlalchemy import select
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)

DEFAULT_MODEL = "gpt-4o-mini"
DEFAULT_QUERY = (
    "electoral list party coalition running or considering running in the Palestinian "
    "Legislative Council election 2026, not already widely reported"
)

_ALLOWED_STATUS_HINTS = {"rumored", "considering", "announced_intention"}

_LIST_SCHEMA = {
    "type": "object",
    "properties": {
        "lists": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "list_name_en": {"type": "string"},
                    "list_name_ar": {"type": "string"},
                    "member_parties": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "name_en": {"type": "string"},
                                "name_ar": {"type": "string"},
                                "abbreviation": {"type": ["string", "null"]},
                            },
                            "required": ["name_en", "name_ar", "abbreviation"],
                            "additionalProperties": False,
                        },
                    },
                    "source_url": {"type": "string"},
                    "status_hint": {
                        "type": "string",
                        "description": "One of: rumored, considering, announced_intention.",
                    },
                },
                "required": ["list_name_en", "list_name_ar", "member_parties", "source_url", "status_hint"],
                "additionalProperties": False,
            },
        },
    },
    "required": ["lists"],
    "additionalProperties": False,
}

_SYSTEM_PROMPT = """\
You are an election-list discovery assistant for a Palestinian election \
intelligence platform. Use web search to find REAL electoral lists (and \
the parties composing them) that are actually running, or credibly \
reported to be considering running, in the Palestinian Legislative \
Council election. Only report a list you actually found via search, \
with a real source_url — never invent a list, a party name, or a status \
claim. status_hint must be exactly one of "rumored", "considering", or \
"announced_intention" — even if a source claims official CEC approval \
or registration, still use "announced_intention" (a human analyst \
verifies the CEC citation separately) rather than inventing a stronger \
status value. Skip lists that are already extremely well-established \
and widely known unless you found genuinely new information about them.
"""


@dataclass
class OpenAiPartyDiscovery:
    api_key: str | None = None
    model: str = DEFAULT_MODEL

    def __post_init__(self) -> None:
        import openai  # local import: optional dependency, not required unless this is used

        self._openai = openai
        self._client = openai.OpenAI(api_key=self.api_key) if self.api_key else openai.OpenAI()

    def discover(self, query: str = DEFAULT_QUERY) -> list[dict]:
        try:
            response = self._client.responses.create(
                model=self.model,
                tools=[{"type": "web_search"}],
                input=[
                    {"role": "system", "content": _SYSTEM_PROMPT},
                    {"role": "user", "content": query},
                ],
                text={
                    "format": {
                        "type": "json_schema",
                        "name": "list_search_results",
                        "schema": _LIST_SCHEMA,
                        "strict": True,
                    }
                },
            )
        except Exception:
            logger.exception("OpenAI party/list discovery: search failed.")
            return []
        try:
            return json.loads(response.output_text).get("lists", [])
        except (AttributeError, json.JSONDecodeError):
            logger.error("OpenAI party/list discovery: could not parse structured output.")
            return []


def _safe_status(hint: str | None) -> RegistrationStatus:
    value = (hint or "").strip().lower()
    if value in _ALLOWED_STATUS_HINTS:
        return RegistrationStatus(value)
    return RegistrationStatus.RUMORED


def _get_or_create_party(db: Session, name_en: str, name_ar: str, abbreviation: str | None) -> tuple[Party, bool]:
    existing = db.scalar(select(Party).where(Party.name_en.ilike(name_en))) if name_en else None
    if existing is None and name_ar:
        existing = db.scalar(select(Party).where(Party.name_ar == name_ar))
    if existing:
        return existing, False
    party = Party(
        name_en=name_en,
        name_ar=name_ar,
        abbreviation=abbreviation,
        registration_status=RegistrationStatus.RUMORED,
        verification_confidence=VerificationConfidence.LOW,
    )
    db.add(party)
    db.flush()
    return party, True


def draft_electoral_lists_from_ai_discovery(
    db: Session, election_id: UUID, api_key: str | None, model: str = DEFAULT_MODEL
) -> dict:
    """Drafts new ElectoralList (+ Party, + ElectoralListParty link) rows
    from AI web search. Never assigns a status above the "considering"
    family — see module docstring."""
    found = OpenAiPartyDiscovery(api_key=api_key, model=model).discover()
    stats = {"found": len(found), "drafted": 0, "skipped_existing": 0, "skipped_incomplete": 0, "parties_created": 0}

    for item in found:
        list_name_en = item.get("list_name_en")
        list_name_ar = item.get("list_name_ar")
        members = item.get("member_parties") or []
        if not list_name_en or not list_name_ar or not members:
            stats["skipped_incomplete"] += 1
            continue

        existing_list = db.scalar(
            select(ElectoralList).where(
                ElectoralList.election_id == election_id,
                (ElectoralList.list_name_en.ilike(list_name_en)) | (ElectoralList.list_name_ar == list_name_ar),
            )
        )
        if existing_list:
            stats["skipped_existing"] += 1
            continue

        electoral_list = ElectoralList(
            election_id=election_id,
            list_name_en=list_name_en,
            list_name_ar=list_name_ar,
            registration_status=_safe_status(item.get("status_hint")),
        )
        db.add(electoral_list)
        db.flush()

        for member in members:
            party, created = _get_or_create_party(
                db, member.get("name_en", ""), member.get("name_ar", ""), member.get("abbreviation")
            )
            if created:
                stats["parties_created"] += 1
            db.add(ElectoralListParty(electoral_list_id=electoral_list.id, party_id=party.id))

        stats["drafted"] += 1

    db.commit()
    return stats
