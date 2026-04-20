from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Database
    database_url: str = "postgresql+asyncpg://inventory:inventory_secret@localhost:5432/inventory_db"
    sync_database_url: str = "postgresql+psycopg2://inventory:inventory_secret@localhost:5432/inventory_db"

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    # JWT
    jwt_secret_key: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 30
    jwt_refresh_token_expire_days: int = 30

    # S3 / MinIO
    s3_endpoint_url: str = "http://localhost:9000"
    s3_bucket_name: str = "inventory-assets"
    s3_access_key: str = "minioadmin"
    s3_secret_key: str = "minioadmin123"

    # App
    app_env: str = "development"
    cors_origins: str = "http://localhost:3000,http://localhost:5173"

    @property
    def cors_origins_list(self) -> List[str]:
        return [o.strip() for o in self.cors_origins.split(",")]


settings = Settings()
