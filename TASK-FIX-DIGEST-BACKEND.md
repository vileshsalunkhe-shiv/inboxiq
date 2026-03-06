# Task: Fix Daily Digest Backend Issues

**Agent:** DEV-BE-premium
**Priority:** CRITICAL (Demo tomorrow)
**Time Estimate:** 20-30 minutes
**Output Directory:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/daily-digest-backend-fixes/`

---

## Objective
Fix critical and high-priority issues found in Sundar's review WITHOUT breaking existing functionality.

---

## Issues to Fix

### 1. DEMO BLOCKER: Missing Preferences Endpoints ❌

**Issue:** iOS code calls `GET/PUT /api/digest/settings` endpoints that don't exist.

**Fix:** Add these endpoints to `digest.py`:

```python
# Add to digest.py

@router.get("/settings", response_model=DigestSettingsOut)
async def get_digest_settings(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get user's digest preferences."""
    return DigestSettingsOut(
        enabled=current_user.digest_enabled,
        preferred_time=current_user.digest_time.strftime("%H:%M") if current_user.digest_time else "07:00",
        last_sent_at=current_user.last_digest_sent_at,
    )

@router.put("/settings", response_model=DigestSettingsOut)
async def update_digest_settings(
    settings: DigestSettingsIn,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update user's digest preferences."""
    from datetime import datetime, time
    
    # Parse time string "HH:MM" to time object
    hour, minute = map(int, settings.preferred_time.split(":"))
    
    current_user.digest_enabled = settings.enabled
    current_user.digest_time = time(hour, minute)
    
    await db.commit()
    await db.refresh(current_user)
    
    return DigestSettingsOut(
        enabled=current_user.digest_enabled,
        preferred_time=current_user.digest_time.strftime("%H:%M"),
        last_sent_at=current_user.last_digest_sent_at,
    )
```

**Add to schemas (create or update `app/schemas/digest.py`):**

```python
from pydantic import BaseModel
from datetime import datetime

class DigestSettingsIn(BaseModel):
    enabled: bool
    preferred_time: str  # Format: "HH:MM" e.g. "07:00"

class DigestSettingsOut(BaseModel):
    enabled: bool
    preferred_time: str
    last_sent_at: datetime | None

    class Config:
        from_attributes = True
```

---

### 2. HIGH PRIORITY: Add Rate Limiting ⚠️

**Issue:** No rate limiting on `/preview` and `/send` endpoints. Could cause service degradation during demo.

**Fix:** Add rate limiting using SlowAPI:

**Step 1:** Add dependency to `requirements.txt`:
```
slowapi==0.1.9
```

**Step 2:** Configure limiter in `main.py`:
```python
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
```

**Step 3:** Apply to digest endpoints in `digest.py`:
```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@router.get("/preview", ...)
@limiter.limit("10/minute")  # Allow 10 previews per minute
async def preview_digest(...):
    ...

@router.post("/send", ...)
@limiter.limit("5/minute")  # Allow 5 sends per minute
async def send_digest(...):
    ...

@router.get("/settings", ...)
@limiter.limit("20/minute")  # Settings can be more frequent
async def get_digest_settings(...):
    ...

@router.put("/settings", ...)
@limiter.limit("20/minute")
async def update_digest_settings(...):
    ...
```

---

### 3. SECURITY: Explicit XSS Escaping 🔒

**Issue:** While Jinja2 auto-escaping is enabled, explicit escaping is best practice for defense-in-depth.

**Fix:** Add explicit escaping (`|e`) to all user-generated content in `digest_email.html`:

```html
<!-- In the email template -->
<div style="font-size:14px;font-weight:700;">
  {{ email.subject|e }}
</div>
<div style="font-size:12px;color:#6b7280;margin-top:4px;">
  {{ email.sender_name|e }}{% if email.sender_email %} · {{ email.sender_email|e }}{% endif %}
</div>
<div style="font-size:13px;color:#374151;margin-top:6px;">
  {{ email.snippet|e }}
</div>
```

Apply to all instances of:
- `{{ email.subject }}` → `{{ email.subject|e }}`
- `{{ email.sender_name }}` → `{{ email.sender_name|e }}`
- `{{ email.sender_email }}` → `{{ email.sender_email|e }}`
- `{{ email.snippet }}` → `{{ email.snippet|e }}`
- `{{ event.title }}` → `{{ event.title|e }}`
- `{{ event.location }}` → `{{ event.location|e }}`

---

## CRITICAL CONSTRAINTS

### DO NOT BREAK EXISTING FUNCTIONALITY
- **Only modify digest-related files**
- **Do not touch existing API endpoints**
- **Do not modify existing services (auth, sync, gmail, calendar)**
- **Do not change database models beyond adding columns**
- **Test that existing endpoints still work after changes**

### Files You Can Modify
✅ `app/api/digest.py` (NEW file - safe to modify)
✅ `app/services/digest_service.py` (NEW file - safe to modify)
✅ `app/templates/digest_email.html` (NEW file - safe to modify)
✅ `app/schemas/digest.py` (NEW file - safe to create)
✅ `requirements.txt` (add slowapi only)
✅ `main.py` (only add limiter setup, don't touch existing routes)

### Files You CANNOT Modify
❌ `app/api/auth_ios.py`
❌ `app/api/emails.py`
❌ `app/api/calendar.py`
❌ `app/services/gmail_service.py`
❌ `app/services/calendar_service.py`
❌ `app/services/sync_service.py`
❌ `app/models/email.py`
❌ `app/models/user.py` (unless adding columns only)

---

## Output Structure

Create this directory structure in your output folder:

```
daily-digest-backend-fixes/
├── README.md                           # What was fixed
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   └── digest.py              # UPDATED with preferences endpoints + rate limiting
│   │   ├── schemas/
│   │   │   └── digest.py              # NEW file with settings schemas
│   │   ├── services/
│   │   │   └── digest_service.py      # NO CHANGES (already good)
│   │   └── templates/
│   │       └── digest_email.html      # UPDATED with explicit escaping
│   ├── requirements.txt               # UPDATED with slowapi
│   └── main.py.patch                  # Patch file for limiter setup
└── INTEGRATION.md                     # How to apply fixes
```

---

## Testing Requirements

Before marking complete, test:
1. **Settings endpoints work:**
   ```bash
   # Get settings
   curl -H "Authorization: Bearer $TOKEN" \
     https://inboxiq-production-5368.up.railway.app/api/digest/settings
   
   # Update settings
   curl -X PUT -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"enabled": true, "preferred_time": "08:00"}' \
     https://inboxiq-production-5368.up.railway.app/api/digest/settings
   ```

2. **Preview still works:**
   ```bash
   curl -H "Authorization: Bearer $TOKEN" \
     https://inboxiq-production-5368.up.railway.app/api/digest/preview
   ```

3. **Send still works:**
   ```bash
   curl -X POST -H "Authorization: Bearer $TOKEN" \
     https://inboxiq-production-5368.up.railway.app/api/digest/send
   ```

4. **Rate limiting triggers:**
   ```bash
   # Call preview 15 times in a row, should get 429 after 10th call
   for i in {1..15}; do
     curl -H "Authorization: Bearer $TOKEN" \
       https://inboxiq-production-5368.up.railway.app/api/digest/preview
   done
   ```

5. **Existing endpoints still work** (smoke test):
   ```bash
   # Auth still works
   curl https://inboxiq-production-5368.up.railway.app/health
   
   # Email sync still works
   curl -H "Authorization: Bearer $TOKEN" \
     https://inboxiq-production-5368.up.railway.app/api/emails/sync
   ```

---

## Success Criteria

✅ GET /api/digest/settings returns user preferences
✅ PUT /api/digest/settings updates preferences
✅ Rate limiting enforced on all digest endpoints
✅ Email template has explicit XSS escaping
✅ All endpoints tested and working
✅ No existing functionality broken
✅ README and integration docs complete

---

## Notes

- **User for testing:** vilesh.salunkhe@gmail.com (user_id: 1ae0ee58-a04f-47b2-ba79-5779bff48b65)
- **Railway URL:** https://inboxiq-production-5368.up.railway.app
- **Sundar's review:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/SUNDAR-DIGEST-REVIEW.md`

**Priority:** Fix the missing preferences endpoints FIRST - this is what will break the demo. Then rate limiting, then XSS escaping.

---

**Good luck! 🔥**
