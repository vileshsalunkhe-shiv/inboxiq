# Test 2: OAuth Flow

**Goal:** Verify OAuth login works without MissingGreenlet error  
**Time:** 5 minutes

---

## Step 1: Start Railway Log Monitor

**Open terminal and run:**
```bash
railway logs --tail 100
```

Keep this terminal visible - we'll watch for OAuth events.

---

## Step 2: Open iOS App

**In Xcode:**
```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ
open InboxIQ.xcodeproj
```

1. Select target device (iPhone simulator)
2. Build and run (⌘R)
3. Wait for app to launch

---

## Step 3: Initiate OAuth

**In the simulator:**
1. Tap "Sign in with Google" button
2. Safari should open automatically
3. Select your Google account (vilesh.salunkhe@gmail.com)
4. Click "Continue" or "Allow"
5. Wait for redirect back to app

---

## Step 4: Watch Railway Logs

**Look for these log entries (in order):**

```
✅ ios_oauth_callback_received
   POST /auth/ios/callback
   
✅ Token exchange with Google
   Status: 200 OK
   
✅ Userinfo fetch
   Status: 200 OK
   
✅ ios_oauth_step_2_user_resolved  ← NEW! Should appear now
   User: vilesh.salunkhe@gmail.com
   
✅ ios_oauth_callback_success
   Redirect: inboxiq://oauth/callback?token=...
```

---

## Expected Results

### ✅ SUCCESS
- App redirects back from Safari
- You see inbox with emails
- No error messages
- Railway logs show all 5 checkpoints above

### ❌ FAILURE (Old Bug)
- App redirects back from Safari
- Error message appears
- Railway logs show:
  ```
  ❌ MissingGreenlet error
  ❌ 500 Internal Server Error
  ```

---

## If Success ✅

1. **Update test results:**
   ```bash
   # Edit RAILWAY-TEST-RESULTS.md
   # Mark Test 2: ✅ PASS
   ```

2. **Move to Test 3:** Email sync (already happened if OAuth worked)

---

## If Failure ❌

1. **Copy Railway error logs:**
   ```bash
   railway logs --tail 50 > /tmp/oauth-error.log
   ```

2. **Share with Shiv:**
   - Error message from app
   - Railway log excerpt
   - What step failed

3. **Don't proceed to other tests** - OAuth is prerequisite

---

## Test Execution

**Start time:** ________  
**End time:** ________  
**Result:** ✅ PASS / ❌ FAIL

**Notes:**
```
[Write any observations here]
```

---

**After this test, we'll check email sync (Test 3)**
