"""FastAPI application entrypoint."""

from __future__ import annotations

import uuid
from datetime import datetime

import redis.asyncio as redis
import sentry_sdk
import structlog
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi_limiter import FastAPILimiter
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from sqlalchemy import text

from app.api import auth_router, auth_ios_router, emails_router, sync_router, actions_router, categorization_router
# Temporarily disabled until migration runs:
# from app.api import digest_router
from app.api.auth_ios import limiter as auth_limiter

# Try to import calendar router, but don't fail if it's missing
calendar_router = None
try:
    from app.api.calendar import router as calendar_router
except ImportError as e:
    import logging
    logging.error(f"Failed to import calendar router: {e}", exc_info=True)
except Exception as e:
    import logging
    logging.error(f"Unexpected error importing calendar router: {e}", exc_info=True)

from app.config import settings
from app.database import engine
from app.utils.logger import setup_logging

logger = structlog.get_logger()


def create_app() -> FastAPI:
    """Create and configure FastAPI app."""
    setup_logging()
    if settings.sentry_dsn:
        sentry_sdk.init(dsn=settings.sentry_dsn, environment=settings.environment, traces_sample_rate=0.1)

    app = FastAPI(title=settings.app_name)
    # Register SlowAPI limiter for auth endpoints (rate limiting).
    app.state.limiter = auth_limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[
            "https://inboxiq-production-5368.up.railway.app",  # Production backend
            "http://localhost:3000",  # Development frontend
            "capacitor://localhost",  # iOS app (Capacitor)
            "ionic://localhost",  # iOS app (Ionic)
        ],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(auth_router)
    app.include_router(auth_ios_router)
    app.include_router(emails_router)
    app.include_router(sync_router)
    # app.include_router(digest_router)  # Temporarily disabled until migration runs
    app.include_router(actions_router)
    app.include_router(categorization_router)
    
    if calendar_router:
        app.include_router(calendar_router)
        logger.info("Calendar router loaded successfully")
    else:
        logger.warning("Calendar router not available - calendar endpoints disabled")

    @app.on_event("startup")
    async def startup() -> None:
        """Initialize services on startup."""
        redis_client = redis.from_url(settings.redis_url, encoding="utf-8", decode_responses=True)
        await FastAPILimiter.init(redis_client)

    @app.get("/health")
    async def health() -> dict:
        """Health check endpoint."""
        status = {"status": "healthy", "timestamp": datetime.utcnow().isoformat(), "checks": {}}
        try:
            async with engine.connect() as conn:
                await conn.execute(text("SELECT 1"))
            status["checks"]["database"] = "ok"
        except Exception:
            status["checks"]["database"] = "failed"
            status["status"] = "unhealthy"

        return status

    @app.middleware("http")
    async def add_request_id(request, call_next):  # type: ignore[no-untyped-def]
        """Attach request ID for tracing."""
        request_id = str(uuid.uuid4())
        structlog.contextvars.bind_contextvars(request_id=request_id)
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response

    return app


app = create_app()
