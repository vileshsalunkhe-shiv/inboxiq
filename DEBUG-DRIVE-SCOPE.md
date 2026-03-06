# Debug: Google Drive Scope Issue

**Time:** 2026-03-05 22:27 CST
**Issue:** OAuth includes Drive scope, but API calls get "insufficientScopes" error

---

## What We Know

**✅ OAuth Callback Success:**
```
scope=email https://www.googleapis.com/auth/drive.file https://www.googleapis.com/auth/gmail.modify ...
```

**❌ Drive API Call Failure:**
```
WARNING: Encountered 403 Forbidden with reason "insufficientScopes"
```

---

## Possible Causes

### 1. Google Cloud Console - App Verification

**Google requires verification for apps using sensitive scopes like Drive.**

Check: https://console.cloud.google.com/apis/credentials/consent

**Unverified apps show warning but usually still work in testing phase.**

**Action:** Check if Drive scope shows "Restricted" or "Sensitive"

---

### 2. OAuth Consent Screen Configuration

**Drive scope must be explicitly added to OAuth consent screen.**

**Steps:**
1. Go to: https://console.cloud.google.com/apis/credentials/consent
2. Click "EDIT APP"
3. Scroll to "Scopes" section
4. Click "ADD OR REMOVE SCOPES"
5. Find and add: `https://www.googleapis.com/auth/drive.file`
6. Save

---

### 3. Refresh Token Scope Mismatch

**Old refresh token may not have Drive scope.**

**Test:** Delete user from database and log in fresh:

```sql
-- In Railway PostgreSQL console
DELETE FROM users WHERE email = 'vilesh.salunkhe@gmail.com';
```

Then log in again on iOS.

---

### 4. Token Introspection

**Check what scopes the access token actually has:**

```bash
# Get your current access token from iOS app (print in Xcode console)
# Then check it:
curl "https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=YOUR_TOKEN"
```

Should show:
```json
{
  "scope": "... https://www.googleapis.com/auth/drive.file ...",
  ...
}
```

---

## Quick Fix to Try

### Option 1: Force Token Refresh

**Delete stored refresh token, force new login:**

```sql
-- Railway PostgreSQL
UPDATE users 
SET google_refresh_token = NULL 
WHERE email = 'vilesh.salunkhe@gmail.com';
```

Then log out/in on iOS.

---

### Option 2: Check Google Console Settings

1. https://console.cloud.google.com/apis/credentials/consent
2. Make sure app is in "Testing" mode (not "Production")
3. Add yourself as test user
4. Make sure Drive API scope is listed in "Scopes for Google APIs"

---

### Option 3: Verify Drive API Enabled

1. https://console.cloud.google.com/apis/dashboard
2. Search for "Google Drive API"
3. Make sure status is "Enabled"
4. Check quota/usage (make sure not rate limited)

---

## Most Likely Fix

**The OAuth Consent Screen needs Drive scope added manually.**

Even though the backend code requests it, Google Console may not allow it unless explicitly configured.

**Steps:**
1. Google Cloud Console → OAuth consent screen
2. Edit App → Scopes section
3. Add `https://www.googleapis.com/auth/drive.file`
4. Save
5. Log out/in on iOS again

---

## If Still Failing

**Create a test endpoint to verify token:**

```python
# Add to backend/app/api/drive.py
@router.get("/debug/token-scopes")
async def debug_token_scopes(current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    auth_service = AuthService(db)
    access_token = await auth_service.get_google_access_token(current_user)
    
    # Check token scopes
    async with httpx.AsyncClient() as client:
        response = await client.get(
            "https://www.googleapis.com/oauth2/v1/tokeninfo",
            params={"access_token": access_token}
        )
        return response.json()
```

Then call: `GET /api/drive/debug/token-scopes`

---

**Next Action:** Check Google Cloud Console OAuth consent screen and verify Drive scope is added there.
