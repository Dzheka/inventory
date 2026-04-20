from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.middleware.auth import get_current_user
from app.models.directory import Zone, Room, Department, AssetCategory
from app.models.user import User
from app.schemas.directories import ZoneSchema, RoomSchema, DepartmentSchema, AssetCategorySchema

router = APIRouter(prefix="/directories", tags=["directories"])


@router.get("/zones", response_model=list[ZoneSchema])
async def list_zones(
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
):
    result = await db.execute(select(Zone).where(Zone.is_active == True).order_by(Zone.name))
    return result.scalars().all()


@router.get("/rooms", response_model=list[RoomSchema])
async def list_rooms(
    zone_id: int | None = None,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
):
    q = select(Room).where(Room.is_active == True)
    if zone_id:
        q = q.where(Room.zone_id == zone_id)
    result = await db.execute(q.order_by(Room.name))
    return result.scalars().all()


@router.get("/departments", response_model=list[DepartmentSchema])
async def list_departments(
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Department).where(Department.is_active == True).order_by(Department.name)
    )
    return result.scalars().all()


@router.get("/categories", response_model=list[AssetCategorySchema])
async def list_categories(
    asset_type: str | None = None,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
):
    q = select(AssetCategory).where(AssetCategory.is_active == True)
    if asset_type:
        q = q.where(AssetCategory.asset_type == asset_type)
    result = await db.execute(q.order_by(AssetCategory.name))
    return result.scalars().all()
