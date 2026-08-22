from fastapi import APIRouter

from . import auth, coalitions, elections, forecast, methodology, news, parties, polls

api_router = APIRouter()
api_router.include_router(elections.router)
api_router.include_router(parties.router)
api_router.include_router(polls.router)
api_router.include_router(forecast.router)
api_router.include_router(coalitions.router)
api_router.include_router(news.router)
api_router.include_router(methodology.router)
api_router.include_router(auth.router)
