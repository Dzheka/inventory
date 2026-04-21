from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.middleware.auth import get_current_user
from app.models.user import User
from app.schemas.assets import AssetSchema, AssetCreateSchema, AssetUpdateSchema
import app.services.assets as asset_svc

router = APIRouter(prefix="/assets", tags=["assets"])


@router.get("", response_model=list[AssetSchema])
async def list_assets(
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=200),
    search: str | None = None,
    status: str | None = None,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
):
    assets, _ = await asset_svc.list_assets(db, page=page, limit=limit, search=search, status=status)
    return assets


@router.get("/barcode/{barcode}", response_model=AssetSchema)
async def get_by_barcode(
    barcode: str,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
):
    asset = await asset_svc.get_asset_by_barcode(db, barcode)
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    return asset


@router.get("/{asset_id}", response_model=AssetSchema)
async def get_asset(
    asset_id: str,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
):
    asset = await asset_svc.get_asset(db, asset_id)
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    return asset


@router.post("", response_model=AssetSchema, status_code=201)
async def create_asset(
    data: AssetCreateSchema,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
):
    return await asset_svc.create_asset(db, data)


@router.patch("/{asset_id}", response_model=AssetSchema)
async def update_asset(
    asset_id: str,
    data: AssetUpdateSchema,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
):
    asset = await asset_svc.get_asset(db, asset_id)
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    return await asset_svc.update_asset(db, asset, data)


@router.delete("/{asset_id}", status_code=204)
async def delete_asset(
    asset_id: str,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
):
    asset = await asset_svc.get_asset(db, asset_id)
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    await asset_svc.delete_asset(db, asset)
