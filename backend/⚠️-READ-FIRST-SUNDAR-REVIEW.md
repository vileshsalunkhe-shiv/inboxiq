# ⚠️ IMPORTANT: READ BEFORE IMPLEMENTING

**To:** DEV-BE-premium  
**From:** Sundar (Security & Quality Review)  
**Date:** 2026-03-04 21:13 CST  
**Status:** APPROVED WITH CHANGES

---

## 🔴 CRITICAL ISSUE (Must Fix First)

### 1. Email Address Validation Missing
**Location:** `/compose` endpoint  
**Problem:** No validation of email addresses in `to`, `cc`, `bcc` fields  
**Impact:** Could break email sending, Gmail API errors  
**Fix:** Add `email-validator` library

```python
# Add to requirements.txt
email-validator==2.1.0

# In compose endpoint:
from email_validator import validate_email, EmailNotValidError

def validate_recipients(emails: list[str]):
    for email in emails:
        try:
            validate_email(email)
        except EmailNotValidError:
            raise HTTPException(400, f"Invalid email: {email}")
```

---

## 🟠 HIGH PRIORITY (Fix These)

### 2. Inconsistent Error Handling
- Standardize logging across all endpoints
- Use centralized exception handling middleware
- All errors should be logged with context (user_id, email_id, operation)

### 3. Redundant Endpoints
**Remove these duplicates:**
- `PATCH /{email_id}/archive` (keep POST only)
- `PATCH /{email_id}/read` (keep PUT only)

**Keep only:**
- `POST /emails/{id}/archive`
- `PUT /emails/{id}/read`
- `PUT /emails/{id}/star`

### 4. Attachments in Reply/Forward
**Missing:** Attachment support in reply/forward endpoints  
**Add to schemas:**
```python
class ReplyEmailRequest:
    body: str
    reply_all: bool = False
    attachments: Optional[List[str]] = None  # Base64 or file paths

class ForwardEmailRequest:
    to: List[str]
    body: Optional[str] = None
    attachments: Optional[List[str]] = None
```

---

## 🟡 MEDIUM PRIORITY (Nice to Have)

### 5. Missing Spam/Move Endpoints
Implement these if time allows:
- `POST /emails/{id}/spam` - Report spam
- `POST /emails/{id}/move` - Move to folder

### 6. Gmail Scope Checking
Add dependency to verify required scopes before processing:
```python
async def check_gmail_scopes(user: User):
    # Verify user has necessary Gmail scopes
    # If not, return 403 with re-auth instructions
```

---

## ✅ POSITIVE FINDINGS

**These are good - keep doing this:**
- ✅ JWT authentication with `get_current_user`
- ✅ Service layer separation (GmailService)
- ✅ Batch API usage for efficiency
- ✅ Async/await patterns

---

## 📋 Implementation Priority

**Build in this order:**
1. ✅ Add email validation to `/compose` (5 min)
2. ✅ Remove redundant PATCH endpoints (5 min)
3. ✅ Standardize error handling (30 min)
4. ✅ Add attachment support to reply/forward (1 hour)
5. ⏩ Spam/move endpoints (if time allows)
6. ⏩ Scope checking (if time allows)

---

## 🎯 Quality Standards

- All endpoints require auth (JWT)
- All inputs validated (Pydantic + custom validation)
- All errors logged with context
- All Gmail API calls wrapped in try/except
- Rate limiting on high-volume endpoints

---

**Full review:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/SUNDAR-API-REVIEW-2026-03-04.md`

**Ready to build? Fix critical issue first, then proceed!** 🚀
