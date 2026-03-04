"""Tests for action token flow."""

from __future__ import annotations

from datetime import datetime, timedelta
import uuid

import pytest
from httpx import AsyncClient

from app.main import app
from app.database import SessionLocal
from app.models import Email, User
from app.utils.action_tokens import create_action_token
from app.services.gmail_service import GmailService
from app.services.auth_service import AuthService


@pytest.mark.asyncio
async def test_action_token_flow(monkeypatch):
    async with SessionLocal() as db:
        user = User(email=f"test-{uuid.uuid4()}@example.com", google_refresh_token="dummy")
        db.add(user)
        await db.commit()
        await db.refresh(user)

        email = Email(
            user_id=user.id,
            gmail_id="gmail-123",
            subject="Hello",
            sender="sender@example.com",
            snippet="Snippet",
            body="Body",
            received_at=datetime.utcnow(),
            category="test",
            is_unread=True,
            is_archived=False,
        )
        db.add(email)
        await db.commit()
        await db.refresh(email)

        async def fake_get_google_access_token(self, user):
            return "fake-access"

        async def fake_archive_message(self, access_token, message_id):
            return {"id": message_id}

        monkeypatch.setattr(AuthService, "get_google_access_token", fake_get_google_access_token)
        monkeypatch.setattr(GmailService, "archive_message", fake_archive_message)

        token = await create_action_token(db, str(user.id), email.id, "archive")

        async with AsyncClient(app=app, base_url="http://test") as client:
            response = await client.get(f"/actions/{token}")
            assert response.status_code == 200
            assert "archived" in response.text.lower()

            # Token should be marked used
            result = await client.get(f"/actions/{token}")
            assert result.status_code == 400

        # Expired token
        expired_token = await create_action_token(db, str(user.id), email.id, "archive")
        # Manually expire
        from app.models import ActionToken
        from sqlalchemy import select
        from app.utils.security import hash_token

        token_hash = hash_token(expired_token)
        token_row = (
            await db.execute(select(ActionToken).where(ActionToken.token_hash == token_hash))
        ).scalar_one()
        token_row.expires_at = datetime.utcnow() - timedelta(hours=1)
        await db.commit()

        async with AsyncClient(app=app, base_url="http://test") as client:
            response = await client.get(f"/actions/{expired_token}")
            assert response.status_code == 400
