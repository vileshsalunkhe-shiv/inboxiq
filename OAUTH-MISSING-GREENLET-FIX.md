# OAuth MissingGreenlet Fix - 2026-03-04 23:37 CST

## Problem
**Error:** `MissingGreenlet` during iOS OAuth callback on Railway  
**Symptom:** Token exchange succeeds, but user creation/login fails  
**Root Cause:** Accessing database-generated IDs without refreshing object after `flush()`

## Technical Details

In SQLAlchemy async mode, after `await db.flush()`, you must `await db.refresh(obj)` **before** accessing database-generated fields like `obj.id`. Otherwise, SQLAlchemy tries to lazy-load the ID synchronously, causing `MissingGreenlet` error.

### Bug Location #1: auth_service.py (Line 52-53)
**Before:**
```python
await self.db.flush()
digest_settings = DigestSettings(
    user_id=user.id,  # ❌ Accessing user.id without refresh
```

**After:**
```python
await self.db.flush()
await self.db.refresh(user)  # ✅ Refresh to get database-generated ID
digest_settings = DigestSettings(
    user_id=user.id,  # ✅ Now safe to access
```

### Bug Location #2: sync_service.py (Line 152-153)
**Before:**
```python
await self.db.flush()
self.db.add(AIQueue(email_id=email.id))  # ❌ Accessing email.id without refresh
```

**After:**
```python
await self.db.flush()
await self.db.refresh(email)  # ✅ Refresh to get database-generated ID
self.db.add(AIQueue(email_id=email.id))  # ✅ Now safe to access
```

## Files Modified
1. `/backend/app/services/auth_service.py` - Added refresh after user flush
2. `/backend/app/services/sync_service.py` - Added refresh after email flush

## Deployment Steps

### 1. Commit Changes
```bash
cd /projects/inboxiq/backend
git add app/services/auth_service.py app/services/sync_service.py
git commit -m "Fix MissingGreenlet error in async database operations"
git push
```

### 2. Railway Auto-Deploy
Railway will automatically detect the push and redeploy. Watch Railway logs for:
- ✅ Build success
- ✅ Deployment success
- ✅ Health check passing

### 3. Test OAuth Flow
1. Open InboxIQ app on iOS simulator
2. Click "Sign in with Google"
3. Authorize in Safari
4. **Expected:** Successful redirect back to app with JWT tokens
5. **Watch Railway logs:** Should see `ios_oauth_callback_success` instead of `MissingGreenlet`

## Expected Railway Logs (After Fix)
```
INFO:app.api.auth_ios:{"event": "ios_oauth_callback_received", ...}
INFO:httpx:HTTP Request: POST https://oauth2.googleapis.com/token "HTTP/1.1 200 OK"
INFO:httpx:HTTP Request: GET https://www.googleapis.com/oauth2/v2/userinfo "HTTP/1.1 200 OK"
INFO:app.api.auth_ios:{"event": "ios_oauth_step_1_before_get_or_create_user", ...}
INFO:app.api.auth_ios:{"event": "ios_oauth_step_2_user_resolved", ...}
INFO:app.api.auth_ios:{"event": "ios_oauth_step_3_before_store_tokens"}
INFO:app.api.auth_ios:{"event": "ios_oauth_step_4_tokens_stored"}
INFO:app.api.auth_ios:{"event": "ios_oauth_step_5_before_create_token_pair"}
INFO:app.api.auth_ios:{"event": "ios_oauth_step_6_token_pair_created"}
INFO:app.api.auth_ios:{"event": "ios_oauth_callback_success", ...}
INFO: 100.64.0.10:xxxxx - "GET /auth/ios/callback?... HTTP/1.1" 307 Temporary Redirect
```

## Root Cause Analysis

SQLAlchemy's async ORM uses greenlets for managing async database operations. When you:
1. `flush()` - Sends INSERT to database
2. Access `obj.id` - SQLAlchemy needs to fetch the auto-generated ID
3. Without `refresh()` - SQLAlchemy tries to query synchronously
4. Result: `MissingGreenlet` error (no greenlet context available)

**Solution:** Always `await db.refresh(obj)` after `flush()` before accessing database-generated fields.

## Prevention

**Rule:** After `await db.flush()`, always `await db.refresh(obj)` if you need to access database-generated fields (`id`, timestamps, etc.).

**Pattern:**
```python
# ✅ Correct
self.db.add(obj)
await self.db.flush()
await self.db.refresh(obj)  # Get database-generated values
use_obj_id(obj.id)  # Safe

# ❌ Wrong
self.db.add(obj)
await self.db.flush()
use_obj_id(obj.id)  # MissingGreenlet error!
```

## Related Issues
- This bug was present since initial OAuth implementation
- Only appeared in production (Railway) because local SQLite doesn't always trigger it
- Fixed proactively in both auth and sync services

## Status
- ✅ Bug identified (23:37 CST)
- ✅ Fix applied (23:40 CST)
- ⏳ Awaiting Railway deployment
- ⏳ Awaiting OAuth test confirmation

---

**Fixed:** 2026-03-04 23:40 CST  
**By:** Shiv  
**Triggered by:** V's Railway error logs (MissingGreenlet)
