# Debug: Email Body 404 Error

**Problem:** iOS sends valid gmail_id but backend returns 404

**Evidence:**
```
GET /api/emails/19cbf939a6b6fb2b/body HTTP/1.1" 404 Not Found
```

---

## Possible Causes

### 1. Email Not in Backend Database
- iOS CoreData has emails that backend PostgreSQL doesn't
- Could happen if:
  - Emails were synced before but deleted from backend
  - iOS cached old emails that are no longer synced
  - Different user accounts (dev vs prod)

### 2. User ID Mismatch
Backend query:
```python
stmt = select(Email).where(Email.gmail_id == gmail_id, Email.user_id == current_user.id)
```

If JWT token user_id doesn't match email's user_id → 404

### 3. Gmail ID Format Issue
- iOS sends: `19cbf939a6b6fb2b` (looks correct)
- Backend expects same format
- Should work ✅

---

## Debug Steps

### Option 1: Check Backend Database (Railway)

**Query to run in Railway PostgreSQL:**
```sql
-- Check if email exists
SELECT id, gmail_id, subject, user_id 
FROM emails 
WHERE gmail_id = '19cbf939a6b6fb2b';

-- Check all emails for current user
SELECT COUNT(*), user_id 
FROM emails 
GROUP BY user_id;

-- Check email body columns
SELECT id, gmail_id, subject, body_text IS NOT NULL as has_text, body_html IS NOT NULL as has_html
FROM emails
LIMIT 10;
```

### Option 2: Add Debug Logging

**Modify backend endpoint to log:**
```python
@router.get("/{gmail_id}/body", response_model=EmailBodyOut)
async def get_email_body(
    gmail_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> EmailBodyOut:
    logger.info(f"🔍 Fetching body for gmail_id={gmail_id}, user_id={current_user.id}")
    
    stmt = select(Email).where(Email.gmail_id == gmail_id, Email.user_id == current_user.id)
    result = await db.execute(stmt)
    email = result.scalar_one_or_none()
    
    if not email:
        # Check if email exists for ANY user
        all_users_stmt = select(Email).where(Email.gmail_id == gmail_id)
        all_result = await db.execute(all_users_stmt)
        any_email = all_result.scalar_one_or_none()
        
        if any_email:
            logger.error(f"❌ Email {gmail_id} exists but user_id mismatch: {any_email.user_id} != {current_user.id}")
        else:
            logger.error(f"❌ Email {gmail_id} not found in database at all")
        
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Email not found")
```

### Option 3: Force Re-sync in iOS

**iOS App:**
1. Settings → Clear local data (if option exists)
2. OR: Delete app → Reinstall → Login
3. Pull to refresh inbox → Full sync
4. Try "Load Full Email" again

This ensures iOS emails match backend database.

---

## Quick Test

**Can you try this email instead:**

Pick the NEWEST email in your inbox (most recent), tap it, try "Load Full Email".

Newest emails are most likely to be in the backend database.

If that works → older emails not synced
If that fails → user_id or auth issue

---

## Most Likely Cause

**iOS has cached emails from previous sync, but backend database was reset or emails were deleted.**

**Solution:** Force re-sync or wait for iOS to sync newer emails.

**Alternative:** Check Railway database directly to see what emails exist.
