"""API routers."""

from app.api.auth import router as auth_router
from app.api.auth_ios import router as auth_ios_router
from app.api.emails import router as emails_router
from app.api.sync import router as sync_router
from app.api.digest import router as digest_router
from app.api.actions import router as actions_router
from app.api.calendar import router as calendar_router

__all__ = ["auth_router", "auth_ios_router", "emails_router", "sync_router", "digest_router", "actions_router", "calendar_router"]
