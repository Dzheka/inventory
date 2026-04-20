import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    username: str = Field(..., min_length=1, max_length=100)
    password: str = Field(..., min_length=1)


class PinLoginRequest(BaseModel):
    username: str
    pin: str = Field(..., min_length=4, max_length=8)


class RefreshRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds


class UserMe(BaseModel):
    id: uuid.UUID
    username: str
    email: Optional[str]
    full_name: str
    is_active: bool
    roles: list[str]
    created_at: datetime

    model_config = {"from_attributes": True}
