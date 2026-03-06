# Debug: Railway Health Check Failed

**Time:** 08:45 CST  
**Issue:** Deployment failed after email schema fix

---

## Possible Causes

### 1. Pydantic Field Alias Issue

**Our change:**
```python
class EmailOut(BaseModel):
    body_preview: str | None = None
    received_date: datetime | None = None
```

**Problem:** We removed the fields `snippet` and `received_at` but didn't add aliases.

**When serializing:**
```python
EmailOut(
    body_preview=email.snippet,  # ✅ OK
    received_date=email.received_at,  # ✅ OK
)
```

**But Pydantic might look for `body_preview` attribute on Email model**, which doesn't exist (it's called `snippet` in the database).

---

### 2. Missing Import

Check if we're missing any imports in the modified files.

---

### 3. Validation Error

Pydantic might be validating the response and failing because of type mismatches.

---

## Quick Fix: Add Field Aliases

**Update `app/schemas/email.py`:**

```python
from pydantic import BaseModel, Field

class EmailOut(BaseModel):
    id: str
    gmail_id: str
    subject: str | None = None
    sender: str | None = None
    body_preview: str | None = None  # iOS field name
    received_date: datetime | None = None  # iOS field name
    is_unread: bool = True
    is_starred: bool = False
    category: str | None = None
    ai_summary: str | None = None
    ai_confidence: float | None = None
    
    class Config:
        # This tells Pydantic to accept both field names
        populate_by_name = True
```

**This way:**
- iOS gets `body_preview` and `received_date`
- We can still pass `snippet=...` and `received_at=...` when creating the object
- Pydantic won't complain

---

## Alternative: Explicit Mapping

**Keep field names as `snippet` and `received_at` in schema**, but use `alias` for serialization:

```python
from pydantic import BaseModel, Field

class EmailOut(BaseModel):
    id: str
    gmail_id: str
    subject: str | None = None
    sender: str | None = None
    snippet: str | None = Field(None, serialization_alias="body_preview")
    received_at: datetime | None = Field(None, serialization_alias="received_date")
    is_unread: bool = True
    is_starred: bool = False
    category: str | None = None
    ai_summary: str | None = None
    ai_confidence: float | None = None
```

This way:
- Database model uses `snippet` and `received_at`
- API response sends `body_preview` and `received_date`
- No need to change serialization code

---

## Check Railway Logs

**V - can you share the Railway error logs?**

Look for:
- `ImportError`
- `ValidationError`
- `AttributeError`
- Python traceback

---

## Test Locally First

```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend

# Start backend locally
uvicorn app.main:app --reload

# In another terminal, test health check
curl localhost:8000/health

# If that works, test emails endpoint
curl -H "Authorization: Bearer $TOKEN" localhost:8000/emails
```

If local works but Railway fails, it's a deployment issue (not code issue).

---

**Next:** Get Railway error logs to identify exact failure point
