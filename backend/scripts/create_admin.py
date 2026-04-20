"""
Run: python -m scripts.create_admin --username admin --password secret
Creates the first admin user.
"""
import asyncio
import argparse
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from sqlalchemy import select
from app.database import AsyncSessionLocal
from app.models.user import User, UserRole, Role
from app.services.auth import hash_password
import uuid


async def create_admin(username: str, password: str, full_name: str) -> None:
    async with AsyncSessionLocal() as session:
        # Check existing
        result = await session.execute(select(User).where(User.username == username))
        if result.scalar_one_or_none():
            print(f"User '{username}' already exists.")
            return

        # Get admin role
        role_result = await session.execute(select(Role).where(Role.name == "admin"))
        admin_role = role_result.scalar_one_or_none()
        if not admin_role:
            print("Admin role not found. Run migrations first.")
            return

        user = User(
            id=uuid.uuid4(),
            username=username,
            full_name=full_name,
            hashed_password=hash_password(password),
            is_active=True,
        )
        session.add(user)
        await session.flush()

        session.add(UserRole(user_id=user.id, role_id=admin_role.id))
        await session.commit()
        print(f"Admin user '{username}' created successfully.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--username", required=True)
    parser.add_argument("--password", required=True)
    parser.add_argument("--full-name", default="Administrator")
    args = parser.parse_args()
    asyncio.run(create_admin(args.username, args.password, args.full_name))
