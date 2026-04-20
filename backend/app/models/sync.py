import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import String, DateTime, Integer, Text
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.dialects.postgresql import UUID, JSONB

from app.database import Base


class SyncQueue(Base):
    __tablename__ = "sync_queue"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    device_id: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    operation: Mapped[str] = mapped_column(String(50), nullable=False)  # create, update, delete
    entity_type: Mapped[str] = mapped_column(String(100), nullable=False)
    entity_id: Mapped[str] = mapped_column(String(100), nullable=False)
    payload: Mapped[Optional[dict]] = mapped_column(JSONB, nullable=True)
    status: Mapped[str] = mapped_column(String(50), default="pending", nullable=False, index=True)
    retry_count: Mapped[int] = mapped_column(Integer, default=0)
    error_message: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    processed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
