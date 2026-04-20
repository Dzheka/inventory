from datetime import datetime
from typing import Optional

from sqlalchemy import String, DateTime, ForeignKey, Text, Boolean, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Zone(Base):
    __tablename__ = "zones"

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    rooms: Mapped[list["Room"]] = relationship(back_populates="zone")


class Room(Base):
    __tablename__ = "rooms"

    id: Mapped[int] = mapped_column(primary_key=True)
    zone_id: Mapped[int] = mapped_column(ForeignKey("zones.id", ondelete="SET NULL"), nullable=True)
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    floor: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    zone: Mapped[Optional["Zone"]] = relationship(back_populates="rooms")
    assets: Mapped[list["Asset"]] = relationship(back_populates="room")


class Department(Base):
    __tablename__ = "departments"

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    parent_id: Mapped[Optional[int]] = mapped_column(ForeignKey("departments.id"), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    parent: Mapped[Optional["Department"]] = relationship(
        "Department",
        back_populates="children",
        primaryjoin="Department.parent_id == remote(Department.id)",
    )
    children: Mapped[list["Department"]] = relationship(
        "Department",
        back_populates="parent",
        primaryjoin="remote(Department.parent_id) == Department.id",
    )


class AssetCategory(Base):
    __tablename__ = "asset_categories"

    id: Mapped[int] = mapped_column(primary_key=True)
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    # ОС (fixed assets), МБП (low-value items), ТМЗ (inventory/stock)
    asset_type: Mapped[str] = mapped_column(String(10), nullable=False)
    parent_id: Mapped[Optional[int]] = mapped_column(ForeignKey("asset_categories.id"), nullable=True)
    account_code: Mapped[Optional[str]] = mapped_column(String(50), nullable=True)  # 1C accounting code
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    parent: Mapped[Optional["AssetCategory"]] = relationship(
        "AssetCategory",
        back_populates="children",
        primaryjoin="AssetCategory.parent_id == remote(AssetCategory.id)",
    )
    children: Mapped[list["AssetCategory"]] = relationship(
        "AssetCategory",
        back_populates="parent",
        primaryjoin="remote(AssetCategory.parent_id) == AssetCategory.id",
    )
    assets: Mapped[list["Asset"]] = relationship(back_populates="category")
