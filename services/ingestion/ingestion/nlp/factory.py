"""Selects a PoliticalNlpProvider by name (section 54 — no vendor lock-in).

Driven by the same `NLP_PROVIDER` setting the API service reads
(services/api/app/config.py), so both services agree on which backend is
active without duplicating provider-selection logic.
"""

from __future__ import annotations

from .provider import PoliticalNlpProvider


def build_nlp_provider(
    provider_name: str,
    *,
    entity_dictionary: dict[str, list[str]] | None = None,
    anthropic_api_key: str | None = None,
    anthropic_model: str | None = None,
    openai_api_key: str | None = None,
    openai_base_url: str | None = None,
    openai_model: str | None = None,
) -> PoliticalNlpProvider:
    if provider_name == "rules":
        from .rules_provider import RulesBasedNlpProvider

        return RulesBasedNlpProvider(entity_dictionary=entity_dictionary or {})

    if provider_name == "anthropic_compatible":
        from .anthropic_provider import AnthropicNlpProvider

        kwargs = {"api_key": anthropic_api_key}
        if anthropic_model:
            kwargs["model"] = anthropic_model
        return AnthropicNlpProvider(**kwargs)

    if provider_name == "openai_compatible":
        from .openai_provider import OpenAiNlpProvider

        kwargs = {"api_key": openai_api_key, "base_url": openai_base_url}
        if openai_model:
            kwargs["model"] = openai_model
        return OpenAiNlpProvider(**kwargs)

    raise ValueError(
        f"Unknown NLP_PROVIDER '{provider_name}'. Expected one of: rules, anthropic_compatible, openai_compatible."
    )
