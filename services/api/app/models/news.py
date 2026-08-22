"""News ingestion storage and PoliticalEvent (sections 8-9, 17, 55-56).

Full copyrighted articles are never stored — only permitted metadata plus
a short snippet (section 8)."""

from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, Float, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .base import Base, TimestampMixin, UUIDPrimaryKeyMixin
from .enums import EventCategory, VerificationConfidence
from .types import JSONB, UUID


class NewsSource(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "news_sources"

    name: Mapped[str] = mapped_column(String(300))
    language: Mapped[str] = mapped_column(String(8))
    ingestion_method: Mapped[str] = mapped_column(String(50))  # rss | api | licensed_api | admin_entered | pdf_import
    feed_url: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    respects_robots_txt: Mapped[bool] = mapped_column(Boolean, default=True)
    license_notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    active: Mapped[bool] = mapped_column(Boolean, default=True)


class Article(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "articles"

    news_source_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("news_sources.id"))
    headline: Mapped[str] = mapped_column(String(500))
    author: Mapped[str | None] = mapped_column(String(300), nullable=True)
    published_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    canonical_url: Mapped[str] = mapped_column(String(2000))
    permitted_snippet: Mapped[str | None] = mapped_column(Text, nullable=True)
    image_url: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    app_generated_summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    language: Mapped[str] = mapped_column(String(8))

    duplicate_cluster_id: Mapped[uuid.UUID | None] = mapped_column(nullable=True)
    importance_score: Mapped[float | None] = mapped_column(Float, nullable=True)

    nlp_confidence: Mapped[float | None] = mapped_column(Float, nullable=True)
    human_reviewed: Mapped[bool] = mapped_column(Boolean, default=False)

    entities: Mapped[list[ArticleEntity]] = relationship(back_populates="article")


class ArticleEntity(UUIDPrimaryKeyMixin, Base):
    """Extracted entity mention linking an article to a canonical Party,
    Person, or ElectoralList row. NLP output only — becomes a verified
    fact solely through analyst approval or an authoritative source
    (section 53)."""

    __tablename__ = "article_entities"

    article_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("articles.id"))
    entity_type: Mapped[str] = mapped_column(String(50))  # party | person | electoral_list
    entity_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True))
    mention_text: Mapped[str] = mapped_column(String(500))
    extraction_confidence: Mapped[float] = mapped_column(Float)

    article: Mapped[Article] = relationship(back_populates="entities")


class PoliticalEvent(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    """A discrete, analyst-relevant political event (section 17).

    Deliberately kept SEPARATE from the quantitative forecast: events are
    displayed as markers on trend charts, but only statistically
    validated features (poll numbers) are allowed to move the model."""

    __tablename__ = "political_events"

    event_timestamp: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    category: Mapped[EventCategory] = mapped_column(Enum(EventCategory, name="event_category"))
    title_ar: Mapped[str] = mapped_column(String(500))
    title_en: Mapped[str] = mapped_column(String(500))
    description_ar: Mapped[str | None] = mapped_column(Text, nullable=True)
    description_en: Mapped[str | None] = mapped_column(Text, nullable=True)
    related_entity_ids: Mapped[list[str] | None] = mapped_column(JSONB, nullable=True)
    primary_source_ids: Mapped[list[str]] = mapped_column(JSONB)
    confidence: Mapped[VerificationConfidence] = mapped_column(
        Enum(VerificationConfidence, name="verification_confidence")
    )
    magnitude: Mapped[str] = mapped_column(String(20), default="minor")  # minor | moderate | major
    geographic_relevance: Mapped[str | None] = mapped_column(String(200), nullable=True)
    analyst_reviewed: Mapped[bool] = mapped_column(Boolean, default=False)
