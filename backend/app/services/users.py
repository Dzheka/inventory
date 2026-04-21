import uuid

from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User, Role, UserRole
from app.schemas.users import UserCreateSchema, UserUpdateSchema
from app.services.auth import hash_password


async def list_users(db: AsyncSession) -> list[User]:
    result = await db.execute(select(User).order_by(User.created_at))
    return list(result.scalars().all())


async def get_user(db: AsyncSession, user_id: str) -> User | None:
    result = await db.execute(
        select(User).where(User.id == uuid.UUID(user_id))
    )
    return result.scalar_one_or_none()


async def get_user_by_username(db: AsyncSession, username: str) -> User | None:
    result = await db.execute(select(User).where(User.username == username))
    return result.scalar_one_or_none()


async def _get_roles(db: AsyncSession, role_names: list[str]) -> list[Role]:
    result = await db.execute(select(Role).where(Role.name.in_(role_names)))
    return list(result.scalars().all())


async def create_user(db: AsyncSession, data: UserCreateSchema) -> User:
    roles = await _get_roles(db, data.roles)
    if not roles:
        raise ValueError(f"None of the provided roles exist: {data.roles}")

    user = User(
        username=data.username,
        full_name=data.full_name,
        email=data.email,
        hashed_password=hash_password(data.password),
        is_active=True,
    )
    db.add(user)
    await db.flush()

    for role in roles:
        db.add(UserRole(user_id=user.id, role_id=role.id))

    await db.flush()
    await db.refresh(user)
    return user


async def update_user(db: AsyncSession, user: User, data: UserUpdateSchema) -> User:
    if data.full_name is not None:
        user.full_name = data.full_name
    if data.email is not None:
        user.email = data.email
    if data.is_active is not None:
        user.is_active = data.is_active

    if data.roles is not None:
        roles = await _get_roles(db, data.roles)
        if not roles:
            raise ValueError(f"None of the provided roles exist: {data.roles}")
        await db.execute(delete(UserRole).where(UserRole.user_id == user.id))
        for role in roles:
            db.add(UserRole(user_id=user.id, role_id=role.id))

    await db.flush()
    await db.refresh(user)
    return user


async def delete_user(db: AsyncSession, user: User) -> None:
    await db.delete(user)
    await db.flush()


async def change_password(db: AsyncSession, user: User, new_password: str) -> None:
    user.hashed_password = hash_password(new_password)
    await db.flush()
