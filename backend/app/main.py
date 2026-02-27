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
from sqlalchemy import text

from app.api import auth_router, digest_router, emails_router, sync_router
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
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(auth_router)
    app.include_router(emails_router)
    app.include_router(sync_router)
    app.include_router(digest_router)

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
