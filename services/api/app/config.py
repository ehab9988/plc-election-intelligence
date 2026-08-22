"""Application configuration, loaded from environment variables.

No secrets are hard-coded — see .env.example at the repo root. The product
name is centralized here so a rename ("PLC Election Intelligence" -> a
commercial brand) touches one place.
"""

from __future__ import annotations

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    product_name: str = "PLC Election Intelligence"
    environment: str = "development"

    database_url: str = "postgresql+psycopg://plc:plc@localhost:5432/plc_election"
    redis_url: str = "redis://localhost:6379/0"

    jwt_secret_key: str = "CHANGE_ME_IN_PRODUCTION"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 30

    cors_allow_origins: list[str] = ["http://localhost:3000"]

    api_v1_prefix: str = "/api/v1"

    nlp_provider: str = "rules"  # rules | openai_compatible | anthropic_compatible
    anthropic_api_key: str | None = None
    anthropic_model: str = "claude-opus-5"
    openai_api_key: str | None = None
    openai_base_url: str | None = None
    openai_model: str = "gpt-4o-mini"

    default_monte_carlo_simulations: int = 20000

    # Ingestion scheduler cadence (services/ingestion/ingestion/scheduler.py)
    ingestion_poll_interval_minutes: int = 15
    forecast_recompute_interval_minutes: int = 60


settings = Settings()
