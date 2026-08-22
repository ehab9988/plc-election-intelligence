from __future__ import annotations

import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from ...db import get_db
from ...models import Article, PoliticalEvent
from ...schemas.common import ORMModel

router = APIRouter(tags=["news"])


class ArticleOut(ORMModel):
    id: uuid.UUID
    news_source_id: uuid.UUID
    headline: str
    author: str | None
    published_at: datetime
    canonical_url: str
    permitted_snippet: str | None
    image_url: str | None
    language: str
    importance_score: float | None


class PoliticalEventOut(ORMModel):
    id: uuid.UUID
    event_timestamp: datetime
    category: str
    title_ar: str
    title_en: str
    description_ar: str | None
    description_en: str | None
    magnitude: str
    confidence: str
    analyst_reviewed: bool


@router.get("/news", response_model=list[ArticleOut])
def list_news(
    limit: int = Query(50, le=200),
    db: Session = Depends(get_db),
) -> list[Article]:
    stmt = select(Article).order_by(Article.published_at.desc()).limit(limit)
    return list(db.scalars(stmt))


@router.get("/events", response_model=list[PoliticalEventOut])
def list_events(
    limit: int = Query(50, le=200),
    db: Session = Depends(get_db),
) -> list[PoliticalEvent]:
    stmt = select(PoliticalEvent).order_by(PoliticalEvent.event_timestamp.desc()).limit(limit)
    return list(db.scalars(stmt))
