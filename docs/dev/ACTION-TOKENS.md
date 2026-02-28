# Action Tokens - Developer Guide

## Overview
Action tokens allow secure, time-limited, single-use actions on emails via public URLs. This enables users to take actions (Archive, Delete, Reply) directly from digest emails without needing to authenticate.

## Token Structure
Tokens are JWTs containing:
```json
{
  "sub": "user_id (UUID)",
  "email_id": 123,
  "action": "archive|delete|reply",
  "exp": 1709251200,
  "type": "action"
}
```

**Field Descriptions:**
- `sub`: User UUID (JWT standard claim for subject)
- `email_id`: Integer ID of the email in our database
- `action`: One of `archive`, `delete`, or `reply`
- `exp`: Unix timestamp for expiration (48 hours from creation)
- `type`: Always `"action"` to distinguish from other JWT types

## Token Lifecycle

### 1. Generation (Digest Service)

Tokens are generated when creating digest emails, one for each action per email.

```python
from app.utils.action_tokens import create_action_token

token = await create_action_token(
    user_id=user.id,
    email_id=email.id,
    action="archive",
    db=db
)
# Returns: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Implementation:**
```python
# app/utils/action_tokens.py
from jose import jwt
import hashlib
from datetime import datetime, timedelta
from app.config import settings

async def create_action_token(
    user_id: str,
    email_id: int,
    action: str,
    db
) -> str:
    """
    Generate a secure, single-use action token.
    
    Args:
        user_id: UUID of the user
        email_id: ID of the email
        action: One of 'archive', 'delete', 'reply'
        db: Database connection
        
    Returns:
        Signed JWT token string
    """
    # Validate action
    if action not in ['archive', 'delete', 'reply']:
        raise ValueError(f"Invalid action: {action}")
    
    # Create payload
    expires_at = datetime.utcnow() + timedelta(hours=48)
    payload = {
        "sub": str(user_id),
        "email_id": email_id,
        "action": action,
        "type": "action",
        "exp": int(expires_at.timestamp())
    }
    
    # Sign token
    token = jwt.encode(
        payload,
        settings.jwt_secret,
        algorithm="HS256"
    )
    
    # Store hash in database
    token_hash = hashlib.sha256(token.encode()).hexdigest()
    await db.execute("""
        INSERT INTO action_tokens (
            token_hash,
            user_id,
            email_id,
            action,
            expires_at
        ) VALUES ($1, $2, $3, $4, $5)
    """, token_hash, user_id, email_id, action, expires_at)
    
    return token
```

### 2. Storage

Token **hashes** (not plaintext tokens) are stored in the `action_tokens` table:

```sql
INSERT INTO action_tokens (token_hash, user_id, email_id, action, expires_at)
VALUES (SHA256(token), user_id, email_id, action, NOW() + INTERVAL '48 hours');
```

**Why hash?**
- Prevents token leakage if database is compromised
- Standard security practice (treat tokens like passwords)
- SHA256 provides fast lookup with strong security

### 3. Validation (Action Endpoint)

When a user clicks an action link, the backend validates the token:

```python
from app.utils.action_tokens import validate_action_token

try:
    payload = await validate_action_token(token, db)
    # Returns: {user_id, email_id, action}
except ValueError as e:
    # Token invalid, expired, or already used
    return error_page(str(e))
```

**Implementation:**
```python
# app/utils/action_tokens.py
from jose import jwt, JWTError
import hashlib
from datetime import datetime

async def validate_action_token(token: str, db) -> dict:
    """
    Validate and decode an action token.
    
    Args:
        token: JWT token string
        db: Database connection
        
    Returns:
        Decoded payload dict
        
    Raises:
        ValueError: If token is invalid, expired, or already used
    """
    # 1. Decode JWT
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=["HS256"]
        )
    except JWTError as e:
        raise ValueError(f"Invalid token signature: {str(e)}")
    
    # 2. Verify token type
    if payload.get("type") != "action":
        raise ValueError("Invalid token type")
    
    # 3. Check database record
    token_hash = hashlib.sha256(token.encode()).hexdigest()
    record = await db.fetch_one("""
        SELECT user_id, email_id, action, used_at, expires_at
        FROM action_tokens
        WHERE token_hash = $1
    """, token_hash)
    
    if not record:
        raise ValueError("Token not found in database")
    
    # 4. Check if already used
    if record['used_at'] is not None:
        raise ValueError("Token has already been used")
    
    # 5. Check expiration (redundant with JWT, but defensive)
    if datetime.utcnow() > record['expires_at']:
        raise ValueError("Token has expired")
    
    # 6. Verify user_id matches
    if str(record['user_id']) != payload['sub']:
        raise ValueError("User ID mismatch")
    
    return {
        "user_id": record['user_id'],
        "email_id": record['email_id'],
        "action": record['action']
    }
```

### 4. Usage (Mark as Used)

After successfully executing the action, mark the token as used:

```python
await mark_token_as_used(token, db)
# Sets used_at = NOW() in database
```

**Implementation:**
```python
async def mark_token_as_used(token: str, db) -> None:
    """
    Mark a token as used to prevent reuse.
    
    Args:
        token: JWT token string
        db: Database connection
    """
    token_hash = hashlib.sha256(token.encode()).hexdigest()
    
    result = await db.execute("""
        UPDATE action_tokens
        SET used_at = NOW()
        WHERE token_hash = $1
        AND used_at IS NULL
    """, token_hash)
    
    # Log if token was already used (shouldn't happen)
    if result == 0:
        logger.warning(
            "attempted_to_mark_used_token",
            token_hash=token_hash[:16]  # Log partial hash
        )
```

## Security Best Practices

### Never Store Tokens Plaintext

Always hash before storing:
```python
import hashlib
token_hash = hashlib.sha256(token.encode()).hexdigest()
```

**Why?**
- Database breach would expose working tokens
- Tokens are bearer credentials (possession = access)
- Hashing is fast (SHA256) and provides strong protection

### Always Validate Ownership

Before performing action, verify the email belongs to the user:

```python
email = await get_email(email_id)
if email.user_id != token_payload["sub"]:
    raise ValueError("Unauthorized")
```

**Why?**
- Defense in depth (shouldn't happen, but check anyway)
- Protects against token generation bugs
- Clear audit trail if something goes wrong

### Handle Errors Gracefully

Provide user-friendly error messages without leaking security details:

```python
try:
    await validate_action_token(token, db)
except ValueError as e:
    error_message = str(e).lower()
    
    if "expired" in error_message:
        return expired_page()
    elif "used" in error_message:
        return already_used_page()
    else:
        # Generic error for security issues
        return invalid_page()
```

### Mark as Used IMMEDIATELY

Mark the token as used before executing the action:

```python
# ✅ CORRECT: Mark as used first
await mark_token_as_used(token, db)
await gmail_api.archive_email(email_id)

# ❌ WRONG: Mark as used after action
await gmail_api.archive_email(email_id)
await mark_token_as_used(token, db)  # If this fails, token can be reused!
```

**Why?**
- Prevents race conditions (double-click)
- If action fails, user won't retry with same link
- Cleaner error handling

## Testing

### Create Test Token

```python
# In tests/test_action_tokens.py
import pytest
from app.utils.action_tokens import create_action_token

@pytest.mark.asyncio
async def test_create_token(test_db, test_user, test_email):
    token = await create_action_token(
        user_id=test_user.id,
        email_id=test_email.id,
        action="archive",
        db=test_db
    )
    
    assert token is not None
    assert isinstance(token, str)
    assert len(token) > 100  # JWTs are long
```

### Test Validation

```python
@pytest.mark.asyncio
async def test_valid_token(test_db, test_token):
    # Valid token should decode successfully
    payload = await validate_action_token(test_token, test_db)
    
    assert payload["action"] == "archive"
    assert payload["email_id"] == 123

@pytest.mark.asyncio
async def test_used_token(test_db, test_token):
    # Mark as used
    await mark_token_as_used(test_token, test_db)
    
    # Should raise error on second use
    with pytest.raises(ValueError, match="already used"):
        await validate_action_token(test_token, test_db)
```

### Test Expiration

```python
from freezegun import freeze_time

@pytest.mark.asyncio
async def test_expired_token(test_db):
    # Create token in the past
    with freeze_time("2024-01-01 12:00:00"):
        token = await create_action_token(
            user_id="test-user",
            email_id=123,
            action="archive",
            db=test_db
        )
    
    # Try to use it 3 days later (past 48h expiration)
    with freeze_time("2024-01-04 12:00:00"):
        with pytest.raises(ValueError, match="expired"):
            await validate_action_token(token, test_db)
```

### Test Invalid Signatures

```python
@pytest.mark.asyncio
async def test_tampered_token(test_db):
    token = await create_action_token(
        user_id="test-user",
        email_id=123,
        action="archive",
        db=test_db
    )
    
    # Tamper with token
    tampered = token[:-5] + "XXXXX"
    
    with pytest.raises(ValueError, match="Invalid token"):
        await validate_action_token(tampered, test_db)
```

## Configuration

In `app/config.py`:
```python
from pydantic import BaseSettings

class Settings(BaseSettings):
    # Action token settings
    action_token_exp_hours: int = 48  # Token lifetime
    jwt_secret: str  # Signing key (same as main JWT secret)
    
    # API base URL (for generating links)
    api_base_url: str = "https://api.inboxiq.com"
    
    class Config:
        env_file = ".env"

settings = Settings()
```

In `.env`:
```bash
ACTION_TOKEN_EXP_HOURS=48
JWT_SECRET=your-secret-key-here
API_BASE_URL=https://api.inboxiq.com
```

## Monitoring

Track token usage for insights and debugging:

```sql
-- Tokens created today
SELECT COUNT(*) 
FROM action_tokens 
WHERE created_at > CURRENT_DATE;

-- Tokens used today
SELECT COUNT(*) 
FROM action_tokens 
WHERE used_at > CURRENT_DATE;

-- Expired unused tokens (cleanup candidates)
SELECT COUNT(*) 
FROM action_tokens 
WHERE expires_at < NOW() 
AND used_at IS NULL;

-- Most common actions
SELECT action, COUNT(*) as usage_count
FROM action_tokens 
WHERE used_at IS NOT NULL
GROUP BY action
ORDER BY usage_count DESC;

-- Average time from creation to usage
SELECT 
    action,
    AVG(EXTRACT(EPOCH FROM (used_at - created_at)) / 3600) as avg_hours
FROM action_tokens
WHERE used_at IS NOT NULL
GROUP BY action;

-- Usage rate by action
SELECT 
    action,
    COUNT(*) as total,
    COUNT(used_at) as used,
    ROUND(100.0 * COUNT(used_at) / COUNT(*), 1) as usage_rate_percent
FROM action_tokens
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY action;
```

### Structured Logging

Log important events for debugging and analytics:

```python
import structlog

logger = structlog.get_logger()

# Token generation
logger.info(
    "action_token_generated",
    user_id=user_id,
    email_id=email_id,
    action=action,
    expires_at=expires_at.isoformat()
)

# Token validation success
logger.info(
    "action_token_validated",
    user_id=payload["user_id"],
    email_id=payload["email_id"],
    action=payload["action"]
)

# Token validation failure
logger.warning(
    "action_token_validation_failed",
    error=str(e),
    token_hash=token_hash[:16]  # Partial hash for privacy
)

# Action execution
logger.info(
    "action_executed",
    user_id=user_id,
    email_id=email_id,
    action=action,
    duration_ms=int((time.time() - start_time) * 1000)
)
```

## Database Maintenance

### Daily Cleanup Job

Remove expired tokens to keep the table lean:

```python
# In scheduler.py or cron job
async def cleanup_expired_tokens():
    """Delete tokens expired more than 7 days ago"""
    result = await db.execute("""
        DELETE FROM action_tokens
        WHERE expires_at < NOW() - INTERVAL '7 days'
    """)
    
    logger.info(
        "expired_tokens_cleaned",
        deleted_count=result
    )
```

**Schedule with APScheduler:**
```python
from apscheduler.schedulers.asyncio import AsyncIOScheduler

scheduler = AsyncIOScheduler()
scheduler.add_job(
    cleanup_expired_tokens,
    trigger="cron",
    hour=3,  # 3 AM daily
    minute=0
)
scheduler.start()
```

### Index Maintenance

Ensure these indexes exist for performance:

```sql
-- Fast lookup by token hash
CREATE INDEX idx_action_tokens_hash 
ON action_tokens(token_hash);

-- Find unused expired tokens (for cleanup)
CREATE INDEX idx_action_tokens_cleanup 
ON action_tokens(expires_at) 
WHERE used_at IS NULL;

-- User's recent tokens (for debugging)
CREATE INDEX idx_action_tokens_user_recent 
ON action_tokens(user_id, created_at DESC);
```

## Troubleshooting

### "Token not found in database"

**Possible causes:**
1. Database cleanup deleted the token (check cleanup job timing)
2. Token was never created (check digest generation logs)
3. Database connection issue during generation

**Debug:**
```sql
SELECT * FROM action_tokens 
WHERE token_hash = 'hash-here' 
ORDER BY created_at DESC 
LIMIT 10;
```

### "Token has already been used"

**Possible causes:**
1. User double-clicked the button
2. Email client pre-fetched the link
3. Multiple devices/tabs open

**Solution:** This is expected behavior. Ensure error page is user-friendly.

### "User ID mismatch"

**Possible causes:**
1. Bug in token generation (wrong user_id)
2. Database corruption (unlikely)
3. JWT secret changed (tokens from old secret won't validate)

**Debug:**
```python
# Decode token manually to inspect payload
from jose import jwt

payload = jwt.decode(token, settings.jwt_secret, algorithms=["HS256"])
print(payload)
```

### High Volume of Expired Tokens

**Possible causes:**
1. Users not clicking action links (low engagement)
2. Digest frequency too high
3. Token expiration too short

**Analyze:**
```sql
SELECT 
    DATE(created_at) as date,
    COUNT(*) as total,
    COUNT(used_at) as used,
    COUNT(*) - COUNT(used_at) as expired_unused
FROM action_tokens
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

## API Reference

### `create_action_token(user_id, email_id, action, db) -> str`

Generate a new action token.

**Parameters:**
- `user_id` (str): User UUID
- `email_id` (int): Email ID
- `action` (str): 'archive', 'delete', or 'reply'
- `db`: Database connection

**Returns:** JWT token string

**Raises:** `ValueError` if action is invalid

---

### `validate_action_token(token, db) -> dict`

Validate and decode a token.

**Parameters:**
- `token` (str): JWT token
- `db`: Database connection

**Returns:** `{"user_id": str, "email_id": int, "action": str}`

**Raises:** `ValueError` if token is invalid, expired, or used

---

### `mark_token_as_used(token, db) -> None`

Mark a token as used.

**Parameters:**
- `token` (str): JWT token
- `db`: Database connection

**Returns:** None

---

## Best Practices Summary

1. ✅ Always hash tokens before storing
2. ✅ Mark as used before executing action
3. ✅ Validate user ownership
4. ✅ Handle errors gracefully with user-friendly messages
5. ✅ Log important events for debugging
6. ✅ Clean up expired tokens regularly
7. ✅ Use indexes for performance
8. ✅ Test edge cases (expiration, reuse, tampering)
9. ✅ Monitor usage rates for product insights
10. ✅ Keep JWT secret secure and rotate periodically

## Further Reading

- [JWT.io](https://jwt.io/) - JWT specification and debugger
- [OWASP Token Binding](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html)
- [FastAPI Security](https://fastapi.tiangolo.com/tutorial/security/)
- [PostgreSQL Indexing](https://www.postgresql.org/docs/current/indexes.html)
