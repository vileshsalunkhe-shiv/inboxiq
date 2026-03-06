# Task: Email Body Backend API

**Agent:** DEV-BE-premium  
**Estimated Time:** 1-2 hours  
**Output Location:** `/projects/inboxiq/backend-email-body/`

## Context

InboxIQ currently shows email snippets (~100-200 chars) in the inbox and detail view. We need to add an endpoint to fetch the full email body on demand when the user taps "Load Full Email" button.

## Current State

**Database:** Emails stored with `body_preview` (snippet) field  
**Gmail Integration:** Working OAuth + sync in `gmail_service.py`  
**API:** Email endpoints in `backend/app/api/emails.py`

## Requirements

### 1. New API Endpoint

**Endpoint:** `GET /api/emails/{email_id}/body`

**Purpose:** Fetch full email body from Gmail API

**Authentication:** Requires valid JWT token (user must own the email)

**Response Format:**
```json
{
  "email_id": "string",
  "body_text": "string | null",
  "body_html": "string | null",
  "has_attachments": "boolean",
  "fetched_at": "datetime"
}
```

### 2. Gmail API Integration

**Location:** Add method to `backend/app/services/gmail_service.py`

**Method:** `get_email_body(service, message_id: str) -> dict`

**Gmail API Call:**
```python
# Fetch full message with body payload
message = service.users().messages().get(
    userId='me',
    id=message_id,
    format='full'  # or 'raw' if needed
).execute()

# Extract body parts:
# - text/plain version
# - text/html version
# - Check for attachments
```

**Return:**
```python
{
    "text": "plain text body or None",
    "html": "html body or None",
    "has_attachments": bool
}
```

### 3. Database Caching (Optional but Recommended)

**Why:** Avoid repeated Gmail API calls for same email

**Options:**
- Add `body_text` and `body_html` columns to `emails` table (simple)
- Create separate `email_bodies` table (normalized)
- Use Redis cache with TTL (fastest, no DB migration)

**Recommendation:** Use existing `emails` table, add nullable columns:
- `body_text: Text | None`
- `body_html: Text | None`
- `body_fetched_at: DateTime | None`

**Migration:** Create Alembic migration to add columns

### 4. API Route Logic

**File:** `backend/app/api/emails.py`

**Pseudo-code:**
```python
@router.get("/emails/{email_id}/body")
async def get_email_body(
    email_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # 1. Verify email belongs to current_user
    email = await db.get(Email, email_id)
    if not email or email.user_id != current_user.id:
        raise HTTPException(404)
    
    # 2. Check if body already cached
    if email.body_text or email.body_html:
        return {
            "email_id": email.id,
            "body_text": email.body_text,
            "body_html": email.body_html,
            "has_attachments": email.has_attachments,
            "fetched_at": email.body_fetched_at
        }
    
    # 3. Fetch from Gmail API
    service = get_gmail_service(current_user)  # OAuth service
    body_data = gmail_service.get_email_body(service, email.gmail_id)
    
    # 4. Cache in database
    email.body_text = body_data["text"]
    email.body_html = body_data["html"]
    email.has_attachments = body_data["has_attachments"]
    email.body_fetched_at = datetime.utcnow()
    await db.commit()
    
    # 5. Return response
    return EmailBodyOut(
        email_id=email.id,
        body_text=email.body_text,
        body_html=email.body_html,
        has_attachments=email.has_attachments,
        fetched_at=email.body_fetched_at
    )
```

### 5. Pydantic Schema

**File:** `backend/app/schemas/email.py`

```python
class EmailBodyOut(BaseModel):
    email_id: str
    body_text: str | None
    body_html: str | None
    has_attachments: bool
    fetched_at: datetime | None
    
    class Config:
        from_attributes = True
```

## Deliverables

1. ✅ New `get_email_body()` method in `gmail_service.py`
2. ✅ Alembic migration for body columns (if using DB cache)
3. ✅ New endpoint in `emails.py`: `GET /api/emails/{email_id}/body`
4. ✅ `EmailBodyOut` schema in `email.py`
5. ✅ Error handling (Gmail API failures, rate limits)
6. ✅ Tests (unit + integration if possible)

## Technical Constraints

- Must use existing OAuth tokens from user record
- Must verify email ownership (user_id match)
- Handle Gmail API errors gracefully
- Consider rate limiting (Gmail API has quotas)
- Support both text and HTML body formats

## Testing

**Manual Test:**
1. Get JWT token for test user
2. Get email_id from `/api/emails` endpoint
3. Call `/api/emails/{email_id}/body`
4. Verify response contains full body
5. Call again → verify cached response (no Gmail API call)

**Curl Example:**
```bash
TOKEN="your_jwt_token"
EMAIL_ID="abc123"
curl -H "Authorization: Bearer $TOKEN" \
  https://inboxiq-production-5368.up.railway.app/api/emails/$EMAIL_ID/body
```

## Success Criteria

- ✅ Endpoint returns full email body (text + HTML)
- ✅ Caching works (second request doesn't call Gmail API)
- ✅ Error handling for non-existent emails
- ✅ Error handling for unauthorized access
- ✅ Works with Railway production environment

## Files to Create/Modify

**New Files:**
- `backend/alembic/versions/XXXXXX_add_email_body_columns.py` (migration)

**Modified Files:**
- `backend/app/services/gmail_service.py` (add `get_email_body()`)
- `backend/app/api/emails.py` (add endpoint)
- `backend/app/schemas/email.py` (add `EmailBodyOut`)
- `backend/app/models/email.py` (add columns if not using migration)

## Output Format

Place all files in: `/projects/inboxiq/backend-email-body/`

Include:
- All modified files (full content)
- Migration file (if created)
- Test results (if tests run)
- README.md with deployment instructions

---

**Start Time:** 2026-03-05 13:15 CST  
**Expected Completion:** 2026-03-05 14:15-15:15 CST
