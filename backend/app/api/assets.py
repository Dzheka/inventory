from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.middleware.auth import get_current_user
from app.models.user import User
from app.schemas.assets import AssetSchema, AssetCreateSchema, AssetUpdateSchema, ImportResultSchema
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


@router.get("/import/template")
async def download_import_template(_: User = Depends(get_current_user)):
    content = asset_svc.generate_import_template()
    return Response(
        content=content,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": "attachment; filename=import_template.xlsx"},
    )


@router.post("/import", response_model=ImportResultSchema)
async def import_assets(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
):
    fname = file.filename or ""
    if not any(fname.lower().endswith(ext) for ext in (".xlsx", ".xls", ".csv")):
        raise HTTPException(status_code=400, detail="Неподдерживаемый формат. Используйте .xlsx или .csv")
    content = await file.read()
    try:
        result = await asset_svc.import_assets_from_file(db, content, fname)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))
    return result


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
