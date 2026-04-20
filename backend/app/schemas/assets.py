import uuid
from datetime import datetime, date
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel


class AssetPhotoSchema(BaseModel):
    id: uuid.UUID
    s3_key: str
    original_filename: Optional[str] = None
    is_primary: bool

    model_config = {"from_attributes": True}


class AssetSchema(BaseModel):
    id: uuid.UUID
    inventory_number: str
    barcode: Optional[str] = None
    name: str
    description: Optional[str] = None
    category_id: Optional[int] = None
    department_id: Optional[int] = None
    room_id: Optional[int] = None
    initial_cost: Optional[Decimal] = None
    residual_value: Optional[Decimal] = None
    commissioning_date: Optional[date] = None
    useful_life_months: Optional[int] = None
    status: str
    inventory_status: str
    one_c_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    last_scanned_at: Optional[datetime] = None
    photos: list[AssetPhotoSchema] = []

    model_config = {"from_attributes": True}


class AssetCreateSchema(BaseModel):
    inventory_number: str
    barcode: Optional[str] = None
    name: str
    description: Optional[str] = None
    category_id: Optional[int] = None
    department_id: Optional[int] = None
    room_id: Optional[int] = None
    initial_cost: Optional[Decimal] = None
    residual_value: Optional[Decimal] = None
    commissioning_date: Optional[date] = None
    useful_life_months: Optional[int] = None
    one_c_id: Optional[str] = None


class AssetUpdateSchema(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    barcode: Optional[str] = None
    category_id: Optional[int] = None
    department_id: Optional[int] = None
    room_id: Optional[int] = None
    status: Optional[str] = None
