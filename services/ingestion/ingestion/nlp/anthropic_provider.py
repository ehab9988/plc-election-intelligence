"""Claude-backed PoliticalNlpProvider (section 53/54).

Uses the Anthropic Messages API with a strict JSON schema
(`output_config.format`) so extraction always returns the exact
entities/events/claims/relationships/dates/confidence/evidence shape the
rest of the pipeline expects — never free text that has to be re-parsed
loosely. This is an EXTRACTION ASSISTANT: `pipeline.requires_human_review`
still gates whether an extraction is trusted enough to write without
analyst approval (see pipeline.py), and the model is never treated as a
source of truth about facts it wasn't given in the input text.

Setup: `pip install anthropic`, then set `ANTHROPIC_API_KEY` (see
.env.example). If unset, `anthropic.Anthropic()` also picks up credentials
from an `ant auth login` profile automatically — see
https://docs.claude.com for the full auth resolution order.
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass

from .provider import ExtractionResult

logger = logging.getLogger(__name__)

DEFAULT_MODEL = "claude-opus-5"

EXTRACTION_SYSTEM_PROMPT = """\
You extract structured political-election facts from a single news \
article for a Palestinian election intelligence platform. You are an \
EXTRACTION ASSISTANT, not a source of truth: extract ONLY what the given \
text explicitly states. Never infer, guess, add outside knowledge, or \
speculate about anything the text does not say. If the text does not \
support a field, omit it rather than filling in a plausible-sounding \
value.

Entities you may extract (entity_type): "party", "person", "electoral_list".
Event categories (category): "party_alliance", "candidate_withdrawal", \
"leadership_change", "endorsement", "legal_change", \
"candidate_disqualification", "list_registration", \
"ceasefire_war_development", "corruption_allegation", "economic_event", \
"campaign_launch", "polling_shock", "other".
Relationship types (relationship_type): "member_of", "affiliated_with", \
"electoral_list_of", "coalition_with", "split_from", "led_by", \
"endorsed_by", "historical_affiliation".

For every entity, event, claim, and relationship you extract, include the \
exact quoted or closely-paraphrased text from the article as evidence — \
do not extract a fact you cannot point to in the source text. Set \
`confidence` (0.0-1.0) to your genuine confidence that the extraction is \
correct and unambiguous given only this text; when in doubt, score lower \
rather than higher.
"""

EXTRACTION_SCHEMA = {
    "type": "object",
    "properties": {
        "entities": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "entity_type": {"type": "string", "enum": ["party", "person", "electoral_list"]},
                    "mention_text": {"type": "string"},
                    "confidence": {"type": "number"},
                },
                "required": ["entity_type", "mention_text", "confidence"],
                "additionalProperties": False,
            },
        },
        "events": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "category": {"type": "string"},
                    "summary": {"type": "string"},
                    "date_mentioned": {"type": ["string", "null"]},
                    "confidence": {"type": "number"},
                },
                "required": ["category", "summary", "confidence"],
                "additionalProperties": False,
            },
        },
        "claims": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "subject": {"type": "string"},
                    "claim_text": {"type": "string"},
                    "confidence": {"type": "number"},
                },
                "required": ["subject", "claim_text", "confidence"],
                "additionalProperties": False,
            },
        },
        "relationships": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "entity_a": {"type": "string"},
                    "entity_b": {"type": "string"},
                    "relationship_type": {"type": "string"},
                    "confidence": {"type": "number"},
                },
                "required": ["entity_a", "entity_b", "relationship_type", "confidence"],
                "additionalProperties": False,
            },
        },
        "dates": {
            "type": "array",
            "items": {"type": "string"},
        },
        "confidence": {"type": "number", "description": "Overall extraction confidence for the whole article."},
        "evidence": {
            "type": "array",
            "items": {"type": "string"},
            "description": "Exact or closely-paraphrased quotes supporting the extractions above.",
        },
    },
    "required": ["entities", "events", "claims", "relationships", "dates", "confidence", "evidence"],
    "additionalProperties": False,
}


@dataclass
class AnthropicNlpProvider:
    api_key: str | None = None
    model: str = DEFAULT_MODEL

    def __post_init__(self) -> None:
        import anthropic  # local import: optional dependency, not required unless this provider is selected

        self._anthropic = anthropic
        self._client = anthropic.Anthropic(api_key=self.api_key) if self.api_key else anthropic.Anthropic()

    def extract(self, text: str, language: str) -> ExtractionResult:
        anthropic = self._anthropic
        try:
            response = self._client.messages.create(
                model=self.model,
                max_tokens=4096,
                system=EXTRACTION_SYSTEM_PROMPT,
                messages=[
                    {
                        "role": "user",
                        "content": f"Article language: {language}\n\nArticle text:\n{text}",
                    }
                ],
                output_config={"format": {"type": "json_schema", "schema": EXTRACTION_SCHEMA}},
            )
        except anthropic.AuthenticationError:
            logger.error("Anthropic NLP provider: authentication failed — check ANTHROPIC_API_KEY.")
            return ExtractionResult()
        except anthropic.RateLimitError as exc:
            logger.warning("Anthropic NLP provider: rate limited (%s) — skipping this article this run.", exc)
            return ExtractionResult()
        except anthropic.APIStatusError as exc:
            logger.error("Anthropic NLP provider: API error %s: %s", exc.status_code, exc.message)
            return ExtractionResult()
        except anthropic.APIConnectionError:
            logger.error("Anthropic NLP provider: network error reaching the Anthropic API.")
            return ExtractionResult()

        text_block = next((b.text for b in response.content if b.type == "text"), None)
        if text_block is None:
            logger.error("Anthropic NLP provider: response had no text block despite output_config.format.")
            return ExtractionResult()

        try:
            data = json.loads(text_block)
        except json.JSONDecodeError:
            logger.error("Anthropic NLP provider: response text was not valid JSON despite output_config.format.")
            return ExtractionResult()

        return ExtractionResult(
            entities=data.get("entities", []),
            events=data.get("events", []),
            claims=data.get("claims", []),
            relationships=data.get("relationships", []),
            dates=data.get("dates", []),
            confidence=float(data.get("confidence", 0.0)),
            evidence=data.get("evidence", []),
        )
