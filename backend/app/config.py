"""Application configuration via environment variables."""

from __future__ import annotations

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """App settings loaded from environment variables."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    environment: str = Field(default="development", alias="ENVIRONMENT")
    app_name: str = Field(default="InboxIQ", alias="APP_NAME")
    api_base_url: str = Field(default="http://localhost:8000", alias="API_BASE_URL")

    # Database
    database_url: str = Field(
        default="postgresql+asyncpg://postgres:postgres@localhost:5432/inboxiq",
        alias="DATABASE_URL",
    )

    def __init__(self, **data):
        """Override to ensure asyncpg driver is used."""
        super().__init__(**data)
        # Convert postgresql:// to postgresql+asyncpg:// if needed
        if self.database_url.startswith("postgresql://"):
            self.database_url = self.database_url.replace(
                "postgresql://", "postgresql+asyncpg://", 1
            )

    # Auth/JWT
    jwt_secret: str = Field(default="change-me", alias="JWT_SECRET")
    jwt_algorithm: str = Field(default="HS256", alias="JWT_ALGORITHM")
    access_token_exp_minutes: int = Field(default=15, alias="ACCESS_TOKEN_EXP_MINUTES")
    refresh_token_exp_days: int = Field(default=30, alias="REFRESH_TOKEN_EXP_DAYS")

    # Google OAuth
    google_client_id: str = Field(default="", alias="GOOGLE_CLIENT_ID")
    google_client_secret: str = Field(default="", alias="GOOGLE_CLIENT_SECRET")
    google_redirect_uri: str = Field(default="", alias="GOOGLE_REDIRECT_URI")

    # Encryption
    encryption_key: str = Field(default="", alias="ENCRYPTION_KEY")

    # Sentry
    sentry_dsn: str = Field(default="", alias="SENTRY_DSN")

    # Redis (rate limiting)
    redis_url: str = Field(default="redis://localhost:6379/0", alias="REDIS_URL")

    # Claude
    claude_api_key: str = Field(default="", alias="CLAUDE_API_KEY")

    # Gmail API
    gmail_api_user: str = Field(default="me", alias="GMAIL_API_USER")

    # Digest
    default_digest_frequency_hours: int = Field(default=12, alias="DEFAULT_DIGEST_FREQUENCY_HOURS")

    # Action tokens
    action_token_exp_hours: int = Field(default=48, alias="ACTION_TOKEN_EXP_HOURS")
    frontend_base_url: str = Field(default="http://localhost:8000", alias="FRONTEND_BASE_URL")


settings = Settings()
