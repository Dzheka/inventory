#!/bin/bash
set -e

echo "Waiting for PostgreSQL..."
until python - <<'PYEOF'
import asyncpg, asyncio, os, sys
async def check():
    url = os.environ.get("DATABASE_URL", "").replace("postgresql+asyncpg://", "")
    # url is now "user:pass@host:port/db"
    try:
        conn = await asyncpg.connect("postgresql://" + url)
        await conn.close()
        print("PostgreSQL is ready.")
    except Exception as e:
        sys.exit(1)
asyncio.run(check())
PYEOF
do
  echo "  ... not ready yet, retrying in 2s"
  sleep 2
done

echo "Running Alembic migrations..."
alembic upgrade head

echo "Starting server..."
exec "$@"
