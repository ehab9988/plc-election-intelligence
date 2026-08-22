"""OpenAI web-search-based poll discovery. Finds recently published
Palestinian election polls and writes them straight into the database as
trusted `Poll` rows (`manually_verified=True`) that immediately feed the
seat forecast — no human review step, by explicit product decision: this
platform runs fully autonomously on whatever OpenAI's web search finds,
end to end.

That is a real accuracy tradeoff, stated plainly rather than hidden: an
LLM web search can misread a rumor as a real poll, get a number wrong, or
find a source that turns out unreliable, and there is no human check left
to catch that before it moves the published forecast. Two automated
(non-human) safeguards remain, because they're just code, not a workflow
gate:
  - a poll is only accepted if it cites a real source_url and reports
    numeric results — see `_looks_plausible` below;
  - `electoral_list_id` on each result is only set when the AI-reported
    label can actually be matched to a real `ElectoralList` for this
    election (`_resolve_electoral_list`) — an unmatched label is stored
    for visibility but excluded from `polling_average()`/the forecast,
    the same way it always was, since "we can't tell which list this is"
    is a genuine data gap, not something a verification step used to
    catch.

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

from app.models import (
    ElectoralList,
    ElectoralListParty,
    Party,
    Poll,
    PollQuestion,
    PollResult,
    Pollster,
    Source,
)
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


def _looks_plausible(item: dict) -> bool:
    """Automated (not human) sanity check: a real source URL, at least
    one result, and every percentage in a physically sensible 0-100
    range. Rejects obvious garbage without a person looking at it."""
    if not item.get("source_url", "").startswith(("http://", "https://")):
        return False
    results = item.get("results") or []
    if not results:
        return False
    return all(0 <= float(r.get("pct", -1)) <= 100 for r in results)


def _resolve_electoral_list(db: Session, election_id: UUID, label: str) -> ElectoralList | None:
    """Best-effort match of an AI-reported label to a real ElectoralList
    for this election — by list name, or by a member party's name.
    Returns None (leaving the result unlinked) rather than guessing."""
    needle = f"%{label.strip()}%"
    match = db.scalar(
        select(ElectoralList).where(
            ElectoralList.election_id == election_id,
            (ElectoralList.list_name_en.ilike(needle)) | (ElectoralList.list_name_ar.ilike(needle)),
        )
    )
    if match:
        return match
    party = db.scalar(select(Party).where((Party.name_en.ilike(needle)) | (Party.name_ar.ilike(needle))))
    if party is None:
        return None
    link = db.scalar(select(ElectoralListParty).where(ElectoralListParty.party_id == party.id))
    if link is None:
        return None
    return db.get(ElectoralList, link.electoral_list_id)


def draft_polls_from_ai_discovery(
    db: Session, election_id: UUID, api_key: str | None, model: str = DEFAULT_MODEL
) -> dict:
    """Writes trusted Poll rows straight from AI web search —
    manually_verified=True, feeding the forecast on the next recompute
    with no human step. See module docstring for the tradeoff and the
    automated (not human) safeguards that remain."""
    found = OpenAiPollDiscovery(api_key=api_key, model=model).discover()
    stats = {
        "found": len(found),
        "drafted": 0,
        "skipped_existing": 0,
        "skipped_incomplete": 0,
        "skipped_implausible": 0,
        "results_matched_to_list": 0,
        "results_unmatched": 0,
    }
    today = datetime.now(UTC).date()

    for item in found:
        if not item.get("pollster_name"):
            stats["skipped_incomplete"] += 1
            continue
        if not _looks_plausible(item):
            stats["skipped_implausible"] += 1
            continue
        results = item["results"]

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
            manually_verified=True,  # trusted automatically — see module docstring
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
            matched_list = _resolve_electoral_list(db, election_id, r["list_or_party_label"])
            stats["results_matched_to_list" if matched_list else "results_unmatched"] += 1
            db.add(
                PollResult(
                    poll_question_id=question.id,
                    electoral_list_id=matched_list.id if matched_list else None,
                    label=r["list_or_party_label"],
                    raw_response_pct=float(r["pct"]),
                    normalized_pct=None,
                )
            )

        stats["drafted"] += 1

    db.commit()
    return stats
