import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class UserSchema(BaseModel):
    id: uuid.UUID
    username: str
    email: Optional[str]
    full_name: str
    is_active: bool
    roles: list[str]
    created_at: datetime
    last_login_at: Optional[datetime]

    model_config = {"from_attributes": True}


class UserCreateSchema(BaseModel):
    username: str = Field(..., min_length=1, max_length=100)
    password: str = Field(..., min_length=6)
    full_name: str = Field(..., min_length=1, max_length=255)
    email: Optional[str] = None
    roles: list[str] = Field(default=["user"])


class UserUpdateSchema(BaseModel):
    full_name: Optional[str] = Field(None, min_length=1, max_length=255)
    email: Optional[str] = None
    is_active: Optional[bool] = None
    roles: Optional[list[str]] = None


class ChangePasswordSchema(BaseModel):
    current_password: str = Field(..., min_length=1)
    new_password: str = Field(..., min_length=6)
