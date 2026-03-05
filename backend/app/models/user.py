"""User model."""

from __future__ import annotations

import uuid
from datetime import datetime, time

from sqlalchemy import Boolean, DateTime, String, Text, Time
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class User(Base):
    """Represents an InboxIQ user."""

    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    google_refresh_token: Mapped[str | None] = mapped_column(Text, nullable=True)
    last_history_id: Mapped[str | None] = mapped_column(String(255), nullable=True)
    
    # Google Calendar OAuth tokens
    calendar_access_token: Mapped[str | None] = mapped_column(Text, nullable=True)
    calendar_refresh_token: Mapped[str | None] = mapped_column(Text, nullable=True)
    calendar_token_expiry: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    
    # Daily digest preferences
    digest_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    digest_time: Mapped[time] = mapped_column(Time, default=time(7, 0), nullable=False)
    last_digest_sent_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    emails = relationship("Email", back_populates="user", cascade="all, delete-orphan")
    categories = relationship("Category", back_populates="user", cascade="all, delete-orphan")
    refresh_tokens = relationship("RefreshToken", back_populates="user", cascade="all, delete-orphan")
    digest_settings = relationship("DigestSettings", back_populates="user", uselist=False)
