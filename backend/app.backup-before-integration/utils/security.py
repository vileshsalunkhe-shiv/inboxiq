"""Security helpers (encryption, hashing)."""

from __future__ import annotations

import hashlib
from datetime import datetime, timedelta
from typing import Any

from cryptography.fernet import Fernet
from jose import jwt

from app.config import settings


def get_cipher() -> Fernet:
    """Return a Fernet cipher for token encryption."""
    if not settings.encryption_key:
        raise ValueError("ENCRYPTION_KEY is not configured")
    return Fernet(settings.encryption_key.encode())


def encrypt_token(token: str) -> str:
    """Encrypt a token string."""
    return get_cipher().encrypt(token.encode()).decode()


def decrypt_token(token_encrypted: str) -> str:
    """Decrypt an encrypted token string."""
    return get_cipher().decrypt(token_encrypted.encode()).decode()


def hash_token(token: str) -> str:
    """Hash refresh tokens for storage."""
    return hashlib.sha256(token.encode()).hexdigest()


def create_access_token(subject: str, expires_minutes: int) -> str:
    """Create a JWT access token."""
    expire = datetime.utcnow() + timedelta(minutes=expires_minutes)
    payload: dict[str, Any] = {"sub": subject, "exp": expire}
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def create_refresh_token(subject: str, expires_days: int) -> tuple[str, datetime]:
    """Create a JWT refresh token."""
    expire = datetime.utcnow() + timedelta(days=expires_days)
    payload: dict[str, Any] = {"sub": subject, "exp": expire, "type": "refresh"}
    token = jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)
    return token, expire
