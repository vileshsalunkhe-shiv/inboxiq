# 🔥 OAUTH FIX - IMMEDIATE ACTIONS

## THE PROBLEM (Found It!)
- Backend expects web OAuth flow: `http://localhost:8000/auth/google/callback`
- iOS app uses native flow: `inboxiq://oauth/callback`
- These are DIFFERENT flows - that's why Google rejects it!

## STEP 1: Fix Google Cloud Console (5 minutes)
**V needs to do this NOW:**

1. Go to https://console.cloud.google.com/
2. Select your project (InboxIQ or whatever it's called)
3. Navigate to **APIs & Services** → **Credentials**
4. Find OAuth client: `535816296321-a722g108h5cqt6ai2v1c7jma0200ij36`
5. Click to edit it
6. Under **Authorized redirect URIs**, ADD:
   ```
   inboxiq://oauth/callback
   ```
7. Keep existing URIs, just add this one
8. Click **SAVE**

## STEP 2: Update Backend (Already Done!)
I've created a new iOS-specific endpoint:
- **New file:** `/auth_ios.py` in backend/app/api/
- **New endpoint:** `POST /auth/ios/login`
- **Key difference:** Uses `inboxiq://oauth/callback` for token exchange

### Backend Changes Made:
1. Created `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend/app/api/auth_ios.py`
2. Updated `app/api/__init__.py` to export new router
3. Updated `app/main.py` to include iOS router
4. Endpoint returns email in response for iOS convenience

## STEP 3: Update iOS App (1 minute)
Replace `AuthViewModel.swift` with the fixed version:

```bash
# V should run this:
cp /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/AuthViewModel-fixed.swift \
   /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ/InboxIQ/AuthViewModel.swift
```

### Key iOS Changes:
- Changed endpoint from `/auth/login` to `/auth/ios/login`
- Updated response model to match backend
- Now handles `user_email` in response

## STEP 4: Restart Backend & Test (2 minutes)

1. **Stop backend if running** (Ctrl+C)

2. **Start backend fresh:**
   ```bash
   cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend
   poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```

3. **Verify new endpoint exists:**
   ```bash
   curl http://localhost:8000/docs
   # Should show /auth/ios/login endpoint
   ```

## STEP 5: Test OAuth Flow (1 minute)

1. **In Xcode:**
   - Clean build folder: Product → Clean Build Folder
   - Build and run on simulator

2. **Test flow:**
   - Tap "Sign in with Google"
   - Complete Google auth
   - Should see "Login Successful!" with email

3. **Watch backend logs:**
   - Should see: `ios_oauth_login_attempt`
   - Then: `ios_oauth_login_success`

## IF IT STILL FAILS

### Check Backend Logs:
```bash
# Look for detailed error messages
# The backend will log exactly what Google returns
```

### Common Issues:
1. **Still getting redirect_uri error?**
   - Google Console changes can take 5 minutes to propagate
   - Try again in a few minutes

2. **Backend not finding endpoint?**
   - Make sure you restarted uvicorn after changes
   - Check `http://localhost:8000/docs` shows `/auth/ios/login`

3. **iOS can't reach backend?**
   - Verify Constants.swift has `apiBaseURL = "http://localhost:8000"`
   - Check Info.plist has ATS exceptions

### Nuclear Option:
If still failing after 15 minutes, we can:
1. Create a NEW OAuth client in Google Console specifically for iOS
2. Use OAuth Playground to manually test

## SUCCESS CRITERIA ✅
When it works you'll see:
1. No Google error page
2. Backend logs show token exchange
3. iOS shows "Login Successful! Email: [user's email]"

---

**Let's get this done! The fix is ready, just needs Google Console update.**