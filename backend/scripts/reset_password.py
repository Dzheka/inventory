import asyncio
import argparse
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from sqlalchemy import update
from app.database import AsyncSessionLocal
from app.models.user import User
from app.services.auth import hash_password


async def reset(username: str, password: str) -> None:
    async with AsyncSessionLocal() as s:
        result = await s.execute(
            update(User)
            .where(User.username == username)
            .values(hashed_password=hash_password(password))
        )
        await s.commit()
        if result.rowcount:
            print(f"Password updated for '{username}'")
        else:
            print(f"User '{username}' not found")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--username", required=True)
    parser.add_argument("--password", required=True)
    args = parser.parse_args()
    asyncio.run(reset(args.username, args.password))
