# InboxIQ - Next Steps: Integration & Testing

**Date:** 2026-03-04 19:07 CST
**Phase:** Security Fixes Complete → Integration & Testing
**Estimated Time:** 3-4 hours

---

## 🎯 Goal

Integrate backend and iOS security fixes into the main codebase and verify everything works before TestFlight.

---

## 📋 Step-by-Step Instructions

### PART 1: Backend Integration (30 minutes)

#### Step 1.1: Backup Current Backend
```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq
cp -r backend/app backend/app.backup-before-integration
echo "✅ Backup created"
```

#### Step 1.2: Copy Security Fixes
```bash
# Copy all fixed files
cp -r backend-security-fixes/app/* backend/app/

echo "✅ Security fixes copied"
```

#### Step 1.3: Review Changes
```bash
# See what changed
cd backend
git diff app/
```

**Key files to review:**
- `app/main.py` - CORS restrictions, rate limiter
- `app/api/auth_ios.py` - Logout endpoint, rate limiting
- `app/services/auth_service.py` - get_or_create_user, sanitized logging
- `app/api/calendar.py` - CSRF validation
- `app/api/emails.py` - Batch API

#### Step 1.4: Test Locally
```bash
cd backend
source .venv/bin/activate
uvicorn app.main:app --reload --port 8000
```

**Open new terminal and test:**
```bash
# Test health check
curl http://localhost:8000/health

# Test CORS (should fail with wrong origin)
curl -H "Origin: https://evil.com" http://localhost:8000/emails

# Test rate limiting (should get 429 after 5 attempts)
# Run this 6 times quickly - the 6th should return 429
for i in {1..6}; do
  echo "Attempt $i:"
  curl -X POST http://localhost:8000/auth/ios/login \
    -H "Content-Type: application/json" \
    -d '{"code":"test_code_123"}' \
    -w "\nHTTP Status: %{http_code}\n\n"
  sleep 0.5
done
```

**Expected results:**
- Health check: 200 OK
- CORS test: CORS error
- Rate limiting: 429 Too Many Requests after 5th attempt

#### Step 1.5: Commit Changes
```bash
cd backend
git add app/
git commit -m "Security hardening: 8 critical/high-priority fixes

- CORS policy restricted
- Sensitive logging sanitized
- JWT logout protection
- Rate limiting on auth endpoints
- Exception handling improved
- Code refactoring (get_or_create_user)
- CSRF protection verified
- Gmail batch API integration

Reviewed-by: Sundar
Fixes: 8/9 critical & high-priority issues from security audit"
```

#### Step 1.6: Deploy to Railway
```bash
cd backend
git push origin main  # Push to GitHub - Railway auto-deploys from there
```

**Monitor deployment:**
- Railway watches your GitHub repo and auto-deploys when you push to `main`
- Go to Railway dashboard: https://railway.app
- Check deployment logs in the Railway UI
- Wait for "Deployed" status
- Test health endpoint: https://inboxiq-production-5368.up.railway.app/health

**Alternative - Check deployment via CLI:**
```bash
railway status  # Check current deployment status
railway logs    # Watch deployment logs in terminal
```

---

### PART 2: iOS Integration (1 hour)

#### Step 2.1: Backup Current iOS App
```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ
cp -r InboxIQ InboxIQ.backup-before-integration
echo "✅ Backup created"
```

#### Step 2.2: Copy Security Fixes
```bash
# Copy all fixed files
cp -r /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios-security-fixes/InboxIQ/* InboxIQ/

echo "✅ Security fixes copied"
```

#### Step 2.3: Open in Xcode
```bash
open /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ/InboxIQ.xcodeproj
```

**In Xcode:**
1. Verify new/modified files are in project (should be auto-included)
2. Check Build Phases → Compile Sources (all Swift files should be there)
3. Clean Build Folder (⇧⌘K)

#### Step 2.4: Extract Railway SSL Hash (CRITICAL)

**This is required for SSL pinning to work!**

1. **Build in DEBUG mode** (default configuration)
2. **Run app** (⌘R) in simulator
3. **Login or sync emails** (make API call to Railway)
4. **Watch Xcode console** for:
   ```
   🔐 SERVER PUBLIC KEY HASH: sha256/AbCdEf123...XyZ789=
   📋 Copy this hash to expectedPublicKeyHashes array
   🌐 Host: inboxiq-production-5368.up.railway.app
   ```

5. **Copy the hash** (full string including `sha256/` prefix)

#### Step 2.5: Update SSL Pinning Configuration

**File:** `InboxIQ/Services/APIClient.swift`

**Find this (around line 30-32):**
```swift
private let expectedPublicKeyHashes: Set<String> = [
    // Placeholder - replace with actual Railway public key hash (base64)
    "RAILWAY_PUBLIC_KEY_HASH_BASE64_HERE"
]
```

**Replace with:**
```swift
private let expectedPublicKeyHashes: Set<String> = [
    "sha256/AbCdEf123...XyZ789="  // Paste hash from console here
]
```

**Save the file (⌘S)**

#### Step 2.6: Build and Test

1. **Clean Build** (⇧⌘K)
2. **Build** (⌘B) - verify no errors
3. **Run** (⌘R) in simulator

**Test all features:**
- [ ] Login (Google OAuth)
- [ ] Email sync (should see emails loading)
- [ ] Calendar integration (authorize calendar if needed)
- [ ] AI categorization (emails should have categories)
- [ ] Category filtering (tap filter button)
- [ ] Pull to refresh
- [ ] Scroll through emails
- [ ] Open email detail
- [ ] Trigger an error (airplane mode) - verify Retry button appears

**Check console for:**
- ✅ "SSL pinning: certificate validated" (good!)
- ❌ "SSL pinning failed" (bad - hash is wrong)
- ✅ No force-unwrap crashes
- ✅ No sensitive data in logs

#### Step 2.7: Test in RELEASE Mode (Optional but Recommended)

1. **Edit Scheme** (Product → Scheme → Edit Scheme)
2. **Run** → Build Configuration → Change to **Release**
3. **Run** (⌘R)
4. **Verify SSL pinning is strict** (no bypass warnings)
5. **Test all features again**

#### Step 2.8: Commit Changes
```bash
cd ios/InboxIQ
git add .
git commit -m "Security hardening: 8 critical/high-priority fixes

iOS Security Fixes:
- Keychain accessibility hardened
- SSL certificate pinning (public-key hash)
- Sensitive logging protected
- CoreData saves off main thread
- Forced unwraps removed
- Error retry buttons added
- Efficient CoreData filtering

Reviewed-by: Sundar
Fixes: 8/8 critical & high-priority issues from security audit
SSL Hash: [REDACTED - see APIClient.swift]"
```

---

### PART 3: End-to-End Testing (1-2 hours)

#### Step 3.1: Test Complete OAuth Flow

1. **Delete app from simulator** (long press → Remove App)
2. **Run app** (⌘R)
3. **Tap Login**
4. **Complete Google OAuth**
5. **Verify:**
   - Redirects to app successfully
   - Tokens saved (no login screen on restart)
   - Email sync starts automatically

#### Step 3.2: Test Email Sync

1. **Sync emails** (pull to refresh)
2. **Verify:**
   - Loading indicator appears
   - Emails populate
   - Categories assigned (colored badges)
   - No crashes
   - UI remains responsive (no freezing)

#### Step 3.3: Test Calendar Integration

1. **Go to Settings → Calendar**
2. **Authorize calendar**
3. **Verify:**
   - OAuth flow works
   - Events appear
   - Dates formatted correctly

#### Step 3.4: Test AI Categorization

1. **Tap "Categorize All Emails"**
2. **Verify:**
   - Progress indicator
   - Toast message on completion
   - Categories updated

#### Step 3.5: Test Filtering

1. **Tap filter button**
2. **Select a category**
3. **Verify:**
   - Filtering is instant (NSPredicate optimization)
   - Correct emails shown
   - Empty state for categories with no emails

#### Step 3.6: Test Error Handling

1. **Enable Airplane Mode** (Settings → Airplane Mode)
2. **Try to sync**
3. **Verify:**
   - Error alert appears
   - **Retry button present** (new feature!)
   - Tapping Retry works when network restored

#### Step 3.7: Test Performance

1. **Sync 50+ emails**
2. **Verify:**
   - Sync completes in reasonable time
   - Scrolling is smooth
   - No memory warnings
   - Battery usage normal

#### Step 3.8: Security Validation

**SSL Pinning Test (Advanced):**
1. Install Charles Proxy or mitmproxy
2. Enable SSL proxying for Railway domain
3. Run app through proxy
4. **Expected:** Connection fails (SSL pinning rejects proxy cert)
5. **Console:** "SSL pinning failed: public key hash mismatch"

**If you don't have a proxy, skip this - SSL pinning is working if API calls succeed in RELEASE mode.**

---

### PART 4: Documentation & Cleanup (15 minutes)

#### Step 4.1: Update CURRENT-SESSION.md
```bash
# Document completion
echo "## Integration Complete ($(date +%Y-%m-%d %H:%M))

### Backend
- ✅ Security fixes integrated
- ✅ Local tests passed
- ✅ Deployed to Railway
- ✅ Production health check: PASSED

### iOS
- ✅ Security fixes integrated
- ✅ SSL hash extracted and configured
- ✅ Simulator tests passed
- ✅ All features functional

### Next: TestFlight Preparation
" >> /Users/openclaw-service/.openclaw/workspace/CURRENT-SESSION.md
```

#### Step 4.2: Take Screenshots (for TestFlight later)
While app is running, capture:
- Login screen
- Email list
- Email detail
- Category filter
- Settings

**Save to:** `/projects/inboxiq/screenshots/`

---

## ✅ Success Checklist

**Backend:**
- [ ] Security fixes copied
- [ ] Local tests passed
- [ ] Deployed to Railway
- [ ] Health check returns 200 OK
- [ ] Rate limiting works
- [ ] CORS restrictions active

**iOS:**
- [ ] Security fixes copied
- [ ] Xcode project updated
- [ ] SSL hash extracted
- [ ] SSL pinning configured
- [ ] Build succeeds (no errors)
- [ ] All features tested in simulator
- [ ] OAuth flow works
- [ ] Email sync works
- [ ] Calendar works
- [ ] Categorization works
- [ ] Filtering works
- [ ] Error handling works (Retry button)
- [ ] No crashes
- [ ] No sensitive data in logs

**Ready for Next Phase:**
- [ ] All checkboxes above are complete
- [ ] No critical bugs found
- [ ] Performance acceptable
- [ ] Changes committed to git
- [ ] Linear updated (issues marked Done, new issues created)

---

## 🚨 If Something Goes Wrong

### Backend Issues

**Problem:** Local tests fail
**Solution:** 
```bash
# Restore backup
rm -rf backend/app
cp -r backend/app.backup-before-integration backend/app
# Review changes and apply manually
```

**Problem:** Railway deployment fails
**Solution:** Check Railway logs, verify environment variables (CLAUDE_API_KEY, etc.)

### iOS Issues

**Problem:** Build errors
**Solution:**
```bash
# Restore backup
rm -rf ios/InboxIQ/InboxIQ
cp -r ios/InboxIQ/InboxIQ.backup-before-integration ios/InboxIQ/InboxIQ
# Review changes and apply manually
```

**Problem:** SSL pinning fails
**Solution:** 
1. Verify you copied the FULL hash (including `sha256/` prefix)
2. Verify hash is in quotes inside the Set
3. Try extracting hash again (might have copied wrong)

**Problem:** App crashes
**Solution:** Check Xcode console for crash logs, likely a force-unwrap that wasn't removed

---

## 🎯 After Completion

**Immediate:**
1. Update Linear (mark integration as Done)
2. Update V in Slack
3. Celebrate! 🎉

**Next Session:**
1. TestFlight build creation
2. Internal beta testing
3. Bug fixes (if any)
4. App Store preparation

---

## 📞 Need Help?

**Questions to ask Shiv:**
- "Show me the SSL hash extraction console output"
- "Why is rate limiting not working?"
- "How do I verify SSL pinning in RELEASE mode?"
- "Backend deployed but health check fails - what's wrong?"

**Common Issues:**
- SSL hash not found → Make sure app is calling Railway API (login or sync)
- Build errors → Clean build folder and try again
- Crashes → Check for force unwraps that weren't removed

---

**Estimated Total Time:** 3-4 hours
**Best Time:** When you have uninterrupted focus
**Prerequisites:** Xcode, Railway access, simulator

**Good luck! You've got this! 🚀**

---

_Generated: 2026-03-04 19:07 CST_
