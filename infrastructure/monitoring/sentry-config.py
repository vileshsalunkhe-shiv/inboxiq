"""
InboxIQ Sentry Configuration
Centralized error tracking and performance monitoring setup
"""

import os
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration
from sentry_sdk.integrations.redis import RedisIntegration
from sentry_sdk.integrations.logging import LoggingIntegration
import logging


def init_sentry(app_name: str = "inboxiq-backend"):
    """
    Initialize Sentry SDK with InboxIQ-specific configuration
    
    Args:
        app_name: Service name for Sentry (backend, worker, etc.)
    """
    
    sentry_dsn = os.getenv("SENTRY_DSN")
    environment = os.getenv("ENVIRONMENT", "development")
    
    # Don't initialize in development without explicit DSN
    if not sentry_dsn:
        if environment == "production":
            logging.warning("SENTRY_DSN not set in production environment!")
        else:
            logging.info("Sentry not initialized (no DSN provided)")
        return
    
    # Sentry configuration
    sentry_sdk.init(
        dsn=sentry_dsn,
        environment=environment,
        
        # Service identification
        server_name=app_name,
        release=get_release_version(),
        
        # Performance monitoring
        traces_sample_rate=get_traces_sample_rate(environment),
        profiles_sample_rate=get_profiles_sample_rate(environment),
        
        # Error sampling (100% in production, can adjust if high volume)
        sample_rate=1.0,
        
        # Integrations
        integrations=[
            # FastAPI integration for request tracking
            FastApiIntegration(
                transaction_style="endpoint",  # Group by endpoint name
                failed_request_status_codes=[500, 599],  # Track 5xx errors
            ),
            
            # SQLAlchemy integration for database query tracking
            SqlalchemyIntegration(),
            
            # Redis integration
            RedisIntegration(),
            
            # Logging integration
            LoggingIntegration(
                level=logging.INFO,        # Capture INFO and above
                event_level=logging.ERROR  # Create events for ERROR and above
            ),
        ],
        
        # Request data
        send_default_pii=False,  # Don't send PII (emails, passwords, etc.)
        max_request_body_size="medium",  # Capture request bodies up to medium size
        
        # Performance
        enable_tracing=True,
        
        # Before send hook for filtering sensitive data
        before_send=before_send_filter,
        
        # Before breadcrumb hook
        before_breadcrumb=before_breadcrumb_filter,
    )
    
    logging.info(f"Sentry initialized for {app_name} in {environment} environment")


def get_release_version() -> str:
    """
    Get the current release version from environment or git
    """
    # Try environment variable first
    release = os.getenv("RELEASE_VERSION")
    if release:
        return release
    
    # Try to get git commit hash
    try:
        import subprocess
        git_hash = subprocess.check_output(
            ['git', 'rev-parse', '--short', 'HEAD'],
            stderr=subprocess.DEVNULL
        ).decode('utf-8').strip()
        return f"git-{git_hash}"
    except Exception:
        return "unknown"


def get_traces_sample_rate(environment: str) -> float:
    """
    Get appropriate traces sample rate based on environment
    
    Production: 10% (reduce cost)
    Staging: 50%
    Development: 100%
    """
    sample_rates = {
        "production": 0.1,
        "staging": 0.5,
        "development": 1.0,
    }
    return sample_rates.get(environment, 0.1)


def get_profiles_sample_rate(environment: str) -> float:
    """
    Get appropriate profiling sample rate
    
    Profiling is resource-intensive, use sparingly
    """
    profile_rates = {
        "production": 0.01,  # 1% of transactions
        "staging": 0.1,      # 10%
        "development": 0.0,  # Disabled
    }
    return profile_rates.get(environment, 0.0)


def before_send_filter(event, hint):
    """
    Filter and scrub sensitive data before sending to Sentry
    
    Args:
        event: Sentry event dict
        hint: Additional context
    
    Returns:
        Modified event or None to drop the event
    """
    
    # Scrub sensitive data from request body
    if "request" in event:
        request = event["request"]
        
        # Remove sensitive headers
        if "headers" in request:
            sensitive_headers = [
                "Authorization",
                "Cookie",
                "X-API-Key",
                "X-Auth-Token",
            ]
            for header in sensitive_headers:
                if header in request["headers"]:
                    request["headers"][header] = "[Filtered]"
        
        # Remove sensitive query parameters
        if "query_string" in request:
            sensitive_params = ["token", "key", "secret", "password"]
            query = request.get("query_string", "")
            for param in sensitive_params:
                if param in query.lower():
                    request["query_string"] = "[Filtered]"
                    break
    
    # Scrub sensitive data from extra context
    if "extra" in event:
        sensitive_keys = ["password", "token", "api_key", "secret", "refresh_token"]
        for key in list(event["extra"].keys()):
            if any(sensitive in key.lower() for sensitive in sensitive_keys):
                event["extra"][key] = "[Filtered]"
    
    # Filter out certain exceptions in development
    environment = os.getenv("ENVIRONMENT", "development")
    if environment == "development":
        # Don't send validation errors in development
        if "exception" in event:
            for exc in event["exception"].get("values", []):
                if exc.get("type") in ["ValidationError", "HTTPException"]:
                    return None
    
    return event


def before_breadcrumb_filter(crumb, hint):
    """
    Filter breadcrumbs before adding to Sentry
    
    Args:
        crumb: Breadcrumb dict
        hint: Additional context
    
    Returns:
        Modified breadcrumb or None to drop it
    """
    
    # Don't log health check requests as breadcrumbs
    if crumb.get("category") == "httplib":
        url = crumb.get("data", {}).get("url", "")
        if "/health" in url:
            return None
    
    # Filter sensitive data from breadcrumb messages
    if "message" in crumb:
        sensitive_patterns = ["password", "token", "api_key", "secret"]
        message = crumb["message"].lower()
        if any(pattern in message for pattern in sensitive_patterns):
            crumb["message"] = "[Filtered breadcrumb with sensitive data]"
    
    return crumb


def capture_message(message: str, level: str = "info", **kwargs):
    """
    Capture a message to Sentry with additional context
    
    Args:
        message: Message to log
        level: Severity level (debug, info, warning, error, fatal)
        **kwargs: Additional context to attach
    """
    with sentry_sdk.push_scope() as scope:
        for key, value in kwargs.items():
            scope.set_extra(key, value)
        sentry_sdk.capture_message(message, level)


def capture_exception(exception: Exception, **kwargs):
    """
    Capture an exception to Sentry with additional context
    
    Args:
        exception: Exception to capture
        **kwargs: Additional context to attach
    """
    with sentry_sdk.push_scope() as scope:
        for key, value in kwargs.items():
            scope.set_extra(key, value)
        sentry_sdk.capture_exception(exception)


def set_user_context(user_id: str, email: str = None):
    """
    Set user context for Sentry events
    
    Args:
        user_id: User ID (UUID)
        email: User email (optional, don't send if PII concerns)
    """
    sentry_sdk.set_user({
        "id": user_id,
        "email": email if os.getenv("SENTRY_SEND_PII") == "true" else None,
    })


def set_transaction_name(name: str):
    """
    Set custom transaction name for performance tracking
    
    Args:
        name: Transaction name (e.g., "sync_emails", "categorize_batch")
    """
    with sentry_sdk.configure_scope() as scope:
        if scope.transaction:
            scope.transaction.name = name


# Context manager for timing operations
class SentryPerformance:
    """
    Context manager for tracking custom operations in Sentry
    
    Example:
        with SentryPerformance("email_sync", op="gmail.sync"):
            sync_emails()
    """
    
    def __init__(self, name: str, op: str = "task"):
        self.name = name
        self.op = op
        self.span = None
    
    def __enter__(self):
        self.span = sentry_sdk.start_span(op=self.op, description=self.name)
        self.span.__enter__()
        return self.span
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.span:
            self.span.__exit__(exc_type, exc_val, exc_tb)


# Decorator for tracking function performance
def track_performance(operation: str = "function"):
    """
    Decorator to track function performance in Sentry
    
    Example:
        @track_performance("ai.categorize")
        async def categorize_email(email):
            ...
    """
    def decorator(func):
        async def async_wrapper(*args, **kwargs):
            with SentryPerformance(func.__name__, op=operation):
                return await func(*args, **kwargs)
        
        def sync_wrapper(*args, **kwargs):
            with SentryPerformance(func.__name__, op=operation):
                return func(*args, **kwargs)
        
        import asyncio
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper
    
    return decorator


# Example usage in FastAPI application
if __name__ == "__main__":
    # Initialize Sentry
    init_sentry("inboxiq-backend")
    
    # Capture a test message
    capture_message("Sentry configuration test", level="info", test=True)
    
    # Test user context
    set_user_context("test-user-123", "test@example.com")
    
    # Test exception capture
    try:
        raise ValueError("Test exception")
    except Exception as e:
        capture_exception(e, test_context="example")
    
    print("Sentry test events sent successfully")
