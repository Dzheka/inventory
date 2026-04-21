from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.middleware.auth import get_current_user, require_admin
from app.models.user import User
from app.schemas.users import UserSchema, UserCreateSchema, UserUpdateSchema, ChangePasswordSchema
from app.services.auth import verify_password
import app.services.users as user_svc

router = APIRouter(prefix="/users", tags=["users"])


def _to_schema(user: User) -> UserSchema:
    return UserSchema(
        id=user.id,
        username=user.username,
        email=user.email,
        full_name=user.full_name,
        is_active=user.is_active,
        roles=user.role_names,
        created_at=user.created_at,
        last_login_at=user.last_login_at,
    )


@router.get("", response_model=list[UserSchema])
async def list_users(
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    users = await user_svc.list_users(db)
    return [_to_schema(u) for u in users]


@router.post("", response_model=UserSchema, status_code=status.HTTP_201_CREATED)
async def create_user(
    data: UserCreateSchema,
    db: AsyncSession = Depends(get_db),
    _: User = Depends(require_admin),
):
    existing = await user_svc.get_user_by_username(db, data.username)
    if existing:
        raise HTTPException(status_code=400, detail="Пользователь с таким именем уже существует")
    try:
        user = await user_svc.create_user(db, data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    return _to_schema(user)


@router.patch("/{user_id}", response_model=UserSchema)
async def update_user(
    user_id: str,
    data: UserUpdateSchema,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    user = await user_svc.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    if str(user.id) == str(current_user.id) and data.is_active is False:
        raise HTTPException(status_code=400, detail="Нельзя деактивировать себя")
    try:
        user = await user_svc.update_user(db, user, data)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    return _to_schema(user)


@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(
    user_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    user = await user_svc.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    if str(user.id) == str(current_user.id):
        raise HTTPException(status_code=400, detail="Нельзя удалить себя")
    await user_svc.delete_user(db, user)


@router.post("/me/change-password", status_code=status.HTTP_204_NO_CONTENT)
async def change_password(
    data: ChangePasswordSchema,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not verify_password(data.current_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Неверный текущий пароль")
    await user_svc.change_password(db, current_user, data.new_password)
