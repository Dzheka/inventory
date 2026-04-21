from fastapi import APIRouter
from app.api.auth import router as auth_router
from app.api.assets import router as assets_router
from app.api.directories import router as directories_router

api_router = APIRouter()
api_router.include_router(auth_router)
api_router.include_router(assets_router)
api_router.include_router(directories_router)
