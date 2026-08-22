"""OpenAI web-search-based poll discovery. Finds recently published
Palestinian election polls and drafts them into the database as
UNVERIFIED rows (`Poll.manually_verified=False`) for analyst review —
mirrors how `jobs.scan_coalition_signals()` drafts `CoalitionEvidence`
rather than writing verified facts (spec section 53).

This is intentional and load-bearing, not an oversight:
`jobs.maybe_recompute_forecast()` only ever triggers on a
manually-verified poll, so an AI-discovered poll can NEVER move the
published forecast until a human (or a documented trusted-pollster
auto-verification policy this build does not implement) marks it
verified. Discovered results are also stored with `electoral_list_id`
unset (the AI-reported party/list label isn't resolved to a canonical
`ElectoralList` row here — see `_resolve_party_mention`-style gap noted
in jobs.py), which additionally keeps them out of
`polling_average()` (services/api/app/api/v1/polls.py skips any
`PollResult` with `electoral_list_id is None`) until an analyst maps the
label and verifies the poll.

Could not be exercised against a real OpenAI account in this development
sandbox — see README "What could not be verified" and
sources/openai_search_adapter.py's docstring for the same caveat about
verifying the exact API shape against current OpenAI docs.
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass
from datetime import UTC, date, datetime
from uuid import UUID

from app.models import Poll, PollQuestion, PollResult, Pollster, Source
from app.models.enums import PollMode, PollPopulation, SourceTier, SourceType
from sqlalchemy import select
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)

DEFAULT_MODEL = "gpt-4o-mini"
DEFAULT_QUERY = (
    "recently published opinion poll Palestinian Legislative Council election 2026 vote share Fatah Hamas"
)

_POLL_SCHEMA = {
    "type": "object",
    "properties": {
        "polls": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "pollster_name": {"type": "string"},
                    "source_url": {"type": "string"},
                    "publication_date": {"type": "string", "description": "ISO 8601 date"},
                    "fieldwork_start": {"type": ["string", "null"]},
                    "fieldwork_end": {"type": ["string", "null"]},
                    "sample_size": {"type": ["integer", "null"]},
                    "results": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "list_or_party_label": {"type": "string"},
                                "pct": {"type": "number"},
                            },
                            "required": ["list_or_party_label", "pct"],
                            "additionalProperties": False,
                        },
                    },
                },
                # OpenAI's strict json_schema mode requires every key in
                # `properties` to also appear here, even nullable ones —
                # optionality is expressed via `"type": [X, "null"]`
                # above, not by omission from `required`.
                "required": [
                    "pollster_name",
                    "source_url",
                    "publication_date",
                    "fieldwork_start",
                    "fieldwork_end",
                    "sample_size",
                    "results",
                ],
                "additionalProperties": False,
            },
        },
    },
    "required": ["polls"],
    "additionalProperties": False,
}

_SYSTEM_PROMPT = """\
You are a poll-discovery assistant for a Palestinian election intelligence \
platform. Use web search to find REAL, ALREADY-PUBLISHED opinion polls \
about the Palestinian Legislative Council election. Only report a poll \
you actually found via search, with a real source_url. Never invent \
numbers, a pollster name, or a date. If a field is not reported by the \
source, omit it (use null) rather than guessing. `results` must be the \
poll's own reported vote-share/support percentages, not your estimate.
"""


@dataclass
class OpenAiPollDiscovery:
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
                        "name": "poll_search_results",
                        "schema": _POLL_SCHEMA,
                        "strict": True,
                    }
                },
            )
        except Exception:
            logger.exception("OpenAI poll discovery: search failed.")
            return []
        try:
            return json.loads(response.output_text).get("polls", [])
        except (AttributeError, json.JSONDecodeError):
            logger.error("OpenAI poll discovery: could not parse structured output.")
            return []


def _get_or_create_pollster(db: Session, name: str) -> Pollster:
    existing = db.scalar(select(Pollster).where(Pollster.name_en.ilike(name)))
    if existing:
        return existing
    pollster = Pollster(name_en=name, name_ar=name)
    db.add(pollster)
    db.flush()
    return pollster


def _parse_date(value: str | None, fallback: date) -> date:
    if not value:
        return fallback
    try:
        return date.fromisoformat(value[:10])
    except ValueError:
        return fallback


def draft_polls_from_ai_discovery(
    db: Session, election_id: UUID, api_key: str | None, model: str = DEFAULT_MODEL
) -> dict:
    """Drafts UNVERIFIED Poll rows from AI web search. Never sets
    `manually_verified=True` — see module docstring."""
    found = OpenAiPollDiscovery(api_key=api_key, model=model).discover()
    stats = {"found": len(found), "drafted": 0, "skipped_existing": 0, "skipped_incomplete": 0}
    today = datetime.now(UTC).date()

    for item in found:
        results = item.get("results") or []
        if not item.get("pollster_name") or not item.get("source_url") or not results:
            stats["skipped_incomplete"] += 1
            continue

        pub_date = _parse_date(item.get("publication_date"), today)
        fieldwork_start = _parse_date(item.get("fieldwork_start"), pub_date)
        fieldwork_end = _parse_date(item.get("fieldwork_end"), pub_date)

        pollster = _get_or_create_pollster(db, item["pollster_name"])

        existing = db.scalar(
            select(Poll).where(
                Poll.pollster_id == pollster.id,
                Poll.election_id == election_id,
                Poll.fieldwork_start == fieldwork_start,
                Poll.fieldwork_end == fieldwork_end,
            )
        )
        if existing:
            stats["skipped_existing"] += 1
            continue

        source = Source(
            name=f"{item['pollster_name']} (AI-discovered)",
            source_type=SourceType.NEWS_ORGANIZATION,
            tier=SourceTier.TIER_3_NEWS,
            url=item["source_url"],
        )
        db.add(source)
        db.flush()

        poll = Poll(
            pollster_id=pollster.id,
            election_id=election_id,
            source_id=source.id,
            publication_date=pub_date,
            fieldwork_start=fieldwork_start,
            fieldwork_end=fieldwork_end,
            sample_size=item.get("sample_size") or 0,
            mode=PollMode.UNKNOWN,
            population=PollPopulation.LIKELY_VOTERS,
            manually_verified=False,  # NEVER True here — see module docstring
            import_timestamp=datetime.now(UTC),
        )
        db.add(poll)
        db.flush()

        question = PollQuestion(
            poll_id=poll.id,
            question_text_ar="(AI-discovered — original question wording not captured)",
            question_type="vote_choice_if_today",
        )
        db.add(question)
        db.flush()

        for r in results:
            db.add(
                PollResult(
                    poll_question_id=question.id,
                    electoral_list_id=None,  # AI-reported label only; not resolved to a canonical list
                    label=r["list_or_party_label"],
                    raw_response_pct=float(r["pct"]),
                    normalized_pct=None,
                )
            )

        stats["drafted"] += 1

    db.commit()
    return stats
