import uuid
from sqlalchemy import select, or_, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.asset import Asset
from app.schemas.assets import AssetCreateSchema, AssetUpdateSchema


async def list_assets(
    db: AsyncSession,
    page: int = 1,
    limit: int = 50,
    search: str | None = None,
    status: str | None = None,
) -> tuple[list[Asset], int]:
    q = select(Asset).options(selectinload(Asset.photos))
    if search:
        q = q.where(or_(
            Asset.name.ilike(f"%{search}%"),
            Asset.inventory_number.ilike(f"%{search}%"),
            Asset.barcode.ilike(f"%{search}%"),
        ))
    if status:
        q = q.where(Asset.status == status)

    count_q = select(func.count()).select_from(q.subquery())
    total = (await db.scalar(count_q)) or 0

    q = q.order_by(Asset.inventory_number).offset((page - 1) * limit).limit(limit)
    result = await db.execute(q)
    return list(result.scalars().all()), total


async def get_asset(db: AsyncSession, asset_id: str) -> Asset | None:
    try:
        uid = uuid.UUID(asset_id)
    except ValueError:
        return None
    result = await db.execute(
        select(Asset).where(Asset.id == uid).options(selectinload(Asset.photos))
    )
    return result.scalar_one_or_none()


async def get_asset_by_barcode(db: AsyncSession, barcode: str) -> Asset | None:
    result = await db.execute(
        select(Asset).where(Asset.barcode == barcode).options(selectinload(Asset.photos))
    )
    return result.scalar_one_or_none()


async def create_asset(db: AsyncSession, data: AssetCreateSchema) -> Asset:
    asset = Asset(**data.model_dump())
    db.add(asset)
    await db.commit()
    await db.refresh(asset, ["photos"])
    return asset


async def update_asset(db: AsyncSession, asset: Asset, data: AssetUpdateSchema) -> Asset:
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(asset, key, value)
    await db.commit()
    await db.refresh(asset, ["photos"])
    return asset


async def delete_asset(db: AsyncSession, asset: Asset) -> None:
    await db.delete(asset)
    await db.commit()
