"""Deterministic, dependency-free default PoliticalNlpProvider.

Does simple keyword/entity-dictionary matching rather than calling an LLM,
so the pipeline has a zero-cost, zero-vendor-dependency baseline (section
54) and every deployment can run end-to-end without any external API key.
Swap in an LLM-backed provider (openai_compatible / anthropic_compatible,
see config.py `nlp_provider`) for materially better recall — this
implementation intentionally trades recall for having no external
dependency and fully deterministic behavior.
"""

from __future__ import annotations

from dataclasses import dataclass

from .provider import ExtractionResult


@dataclass
class RulesBasedNlpProvider:
    """entity_dictionary maps a canonical entity id to a list of surface
    forms/aliases to match (case-insensitive substring match)."""

    entity_dictionary: dict[str, list[str]]

    def extract(self, text: str, language: str) -> ExtractionResult:
        lowered = text.lower()
        entities = []
        for entity_id, aliases in self.entity_dictionary.items():
            for alias in aliases:
                if alias.lower() in lowered:
                    entities.append({"entity_id": entity_id, "mention_text": alias, "confidence": 0.55})
                    break

        return ExtractionResult(
            entities=entities,
            events=[],
            claims=[],
            relationships=[],
            dates=[],
            confidence=0.4 if entities else 0.0,
            evidence=[text[:280]],
        )
