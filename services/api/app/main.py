from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api.v1 import api_router
from .config import settings

app = FastAPI(
    title=settings.product_name,
    description=(
        "Election intelligence, polling aggregation, and statistical "
        "forecasting API. Every forecast figure returned by this API is a "
        "model estimate with an explicit data cutoff, model version, and "
        "uncertainty range — never present it to end users as a bare fact."
    ),
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_allow_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.api_v1_prefix)


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "product_name": settings.product_name}
