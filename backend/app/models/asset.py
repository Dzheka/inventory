import uuid
from datetime import datetime, date
from decimal import Decimal
from typing import Optional
import enum

from sqlalchemy import String, DateTime, ForeignKey, Text, Boolean, Numeric, Date, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.dialects.postgresql import UUID

from app.database import Base


class AssetStatus(str, enum.Enum):
    ACTIVE = "active"
    WRITTEN_OFF = "written_off"
    UNDER_REPAIR = "under_repair"
    TRANSFERRED = "transferred"
    MISSING = "missing"


class InventoryStatus(str, enum.Enum):
    NOT_SCANNED = "not_scanned"
    FOUND = "found"
    NOT_FOUND = "not_found"
    SURPLUS = "surplus"
    DISCREPANCY = "discrepancy"


class Asset(Base):
    __tablename__ = "assets"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    inventory_number: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    barcode: Mapped[Optional[str]] = mapped_column(String(200), nullable=True, index=True)
    name: Mapped[str] = mapped_column(String(500), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)

    # Classification
    category_id: Mapped[Optional[int]] = mapped_column(ForeignKey("asset_categories.id"), nullable=True)
    department_id: Mapped[Optional[int]] = mapped_column(ForeignKey("departments.id"), nullable=True)
    room_id: Mapped[Optional[int]] = mapped_column(ForeignKey("rooms.id"), nullable=True)

    # Financial
    initial_cost: Mapped[Optional[Decimal]] = mapped_column(Numeric(14, 2), nullable=True)
    residual_value: Mapped[Optional[Decimal]] = mapped_column(Numeric(14, 2), nullable=True)
    commissioning_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    useful_life_months: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    # Status
    status: Mapped[str] = mapped_column(String(50), default=AssetStatus.ACTIVE, nullable=False)
    inventory_status: Mapped[str] = mapped_column(
        String(50), default=InventoryStatus.NOT_SCANNED, nullable=False
    )

    # 1C reference
    one_c_id: Mapped[Optional[str]] = mapped_column(String(100), nullable=True, index=True)

    # Timestamps
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )
    last_scanned_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    category: Mapped[Optional["AssetCategory"]] = relationship(back_populates="assets")
    room: Mapped[Optional["Room"]] = relationship(back_populates="assets")
    photos: Mapped[list["AssetPhoto"]] = relationship(back_populates="asset", cascade="all, delete-orphan")


class AssetPhoto(Base):
    __tablename__ = "asset_photos"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    asset_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("assets.id", ondelete="CASCADE"), nullable=False
    )
    s3_key: Mapped[str] = mapped_column(String(500), nullable=False)
    original_filename: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    is_primary: Mapped[bool] = mapped_column(Boolean, default=False)
    uploaded_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    asset: Mapped["Asset"] = relationship(back_populates="photos")
