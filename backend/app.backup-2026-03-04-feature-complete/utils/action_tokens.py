"""Action token helpers."""

from __future__ import annotations

from datetime import datetime, timedelta
import uuid

from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models import ActionToken, Email
from app.utils.security import hash_token


async def create_action_token(
    db: AsyncSession,
    user_id: str,
    email_id: int,
    action: str,
) -> str:
    """Create and persist a signed, single-use action token."""
    expires_at = datetime.utcnow() + timedelta(hours=settings.action_token_exp_hours)
    payload = {
        "sub": str(user_id),
        "email_id": email_id,
        "action": action,
        "exp": expires_at,
    }
    token = jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)
    token_row = ActionToken(
        token_hash=hash_token(token),
        user_id=uuid.UUID(str(user_id)),
        email_id=email_id,
        action=action,
        expires_at=expires_at,
    )
    db.add(token_row)
    await db.commit()
    return token


async def validate_action_token(db: AsyncSession, token: str) -> tuple[ActionToken, dict]:
    """Validate an action token and return its DB row and payload."""
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except JWTError as exc:
        raise ValueError("Invalid or expired token") from exc

    token_hash = hash_token(token)
    result = await db.execute(select(ActionToken).where(ActionToken.token_hash == token_hash))
    token_row = result.scalar_one_or_none()
    if not token_row:
        raise ValueError("Token not found")
    if token_row.used_at:
        raise ValueError("Token already used")
    if token_row.expires_at < datetime.utcnow():
        raise ValueError("Token expired")

    # Ensure payload matches stored data
    if str(payload.get("sub")) != str(token_row.user_id):
        raise ValueError("Token subject mismatch")
    if int(payload.get("email_id")) != token_row.email_id:
        raise ValueError("Token email mismatch")
    if payload.get("action") != token_row.action:
        raise ValueError("Token action mismatch")

    # Ensure email belongs to user
    email_result = await db.execute(
        select(Email).where(Email.id == token_row.email_id, Email.user_id == token_row.user_id)
    )
    email = email_result.scalar_one_or_none()
    if not email:
        raise ValueError("Email not found for user")

    return token_row, payload
