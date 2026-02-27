"""API routers."""

from app.api.auth import router as auth_router
from app.api.emails import router as emails_router
from app.api.sync import router as sync_router
from app.api.digest import router as digest_router

__all__ = ["auth_router", "emails_router", "sync_router", "digest_router"]
