from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class ZoneSchema(BaseModel):
    id: int
    code: str
    name: str
    description: Optional[str] = None
    is_active: bool

    model_config = {"from_attributes": True}


class RoomSchema(BaseModel):
    id: int
    zone_id: Optional[int] = None
    code: str
    name: str
    floor: Optional[int] = None
    is_active: bool

    model_config = {"from_attributes": True}


class DepartmentSchema(BaseModel):
    id: int
    code: str
    name: str
    parent_id: Optional[int] = None
    is_active: bool

    model_config = {"from_attributes": True}


class AssetCategorySchema(BaseModel):
    id: int
    code: str
    name: str
    asset_type: str
    parent_id: Optional[int] = None
    account_code: Optional[str] = None
    is_active: bool

    model_config = {"from_attributes": True}
