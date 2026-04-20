from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.middleware.auth import get_current_user
from app.models.audit import AuditLog
from app.models.user import User
from app.schemas.auth import LoginRequest, RefreshRequest, TokenResponse, UserMe
from app.services.auth import (
    authenticate_user,
    create_access_token,
    create_refresh_token,
    decode_token,
    get_user_by_id,
)
from app.config import settings

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=TokenResponse)
async def login(
    body: LoginRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    user = await authenticate_user(db, body.username, body.password)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    access_token = create_access_token(str(user.id), user.role_names)
    refresh_token = create_refresh_token(str(user.id))

    # Update last login
    user.last_login_at = datetime.utcnow()

    # Audit
    db.add(AuditLog(
        user_id=user.id,
        action="login",
        entity_type="user",
        entity_id=str(user.id),
        ip_address=request.client.host if request.client else None,
        user_agent=request.headers.get("user-agent"),
    ))

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.jwt_access_token_expire_minutes * 60,
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    body: RefreshRequest,
    db: AsyncSession = Depends(get_db),
):
    from jose import JWTError
    try:
        payload = decode_token(body.refresh_token)
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")
        user_id = payload.get("sub")
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired refresh token")

    user = await get_user_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    access_token = create_access_token(str(user.id), user.role_names)
    new_refresh_token = create_refresh_token(str(user.id))

    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh_token,
        expires_in=settings.jwt_access_token_expire_minutes * 60,
    )


@router.get("/me", response_model=UserMe)
async def get_me(current_user: User = Depends(get_current_user)):
    return UserMe(
        id=current_user.id,
        username=current_user.username,
        email=current_user.email,
        full_name=current_user.full_name,
        is_active=current_user.is_active,
        roles=current_user.role_names,
        created_at=current_user.created_at,
    )
