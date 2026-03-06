# OAuth Login Loop - Debug Guide
**Issue:** After signing in with Google, app returns to login screen
**Created:** 2026-03-04 23:24 CST

---

## ✅ Changes Made

**Added comprehensive logging to `AuthViewModel.swift`:**
1. Logs OAuth callback URL when received
2. Logs all query parameters from backend
3. Logs missing parameters (if any)
4. Logs when tokens are saved
5. Logs when `isAuthenticated` changes
6. Logs session load on app start

---

## 🔍 How to Debug (In Xcode)

### Step 1: Clean Build & Run
```bash
1. Clean: ⇧⌘K (Shift-Command-K)
2. Build: ⌘B (Command-B)
3. Run: ⌘R (Command-R)
```

### Step 2: Watch Console Output
**Bottom panel in Xcode shows console logs**

When you sign in, you should see:

**Good Flow (Success):**
```
🔗 OAuth callback received: inboxiq://login?access_token=...
📋 Query parameters:
  - access_token: eyJhbGciOiJIUzI1NiIs...
  - refresh_token: eyJhbGciOiJIUzI1NiIs...
  - user_email: your.email@gmail.com...
  - user_id: 12345678-1234-1234-...
🔄 Setting isAuthenticated = true
✅ Login successful for your.email@gmail.com with backend user_id: 12345678...
✅ isAuthenticated is now: true
```

**Bad Flow (Missing Parameters):**
```
🔗 OAuth callback received: inboxiq://login?error=...
❌ Missing tokens or user_id in callback
  access_token: MISSING
  refresh_token: MISSING
  user_email: present
  user_id: MISSING
```

### Step 3: Identify the Issue

**If you see "Missing tokens":**
- Backend isn't returning proper redirect URL
- Check Railway backend logs
- Verify `/auth/ios/callback` endpoint is working

**If you see "Login successful" but still shows login screen:**
- State isn't updating correctly
- Add breakpoint at line ~60 (`isAuthenticated = true`)
- Verify it actually executes

**If you see nothing in console:**
- OAuth callback URL isn't being received
- Check URL scheme in Info.plist
- Verify `inboxiq://` scheme is registered

---

## 🎯 Common Issues & Fixes

### Issue 1: Backend Not Returning Tokens
**Symptoms:** Console shows "Missing tokens" errors
**Fix:** Check Railway backend logs for `/auth/ios/callback` errors

**To check backend:**
```bash
# Test if backend is responding
curl https://inboxiq-production-5368.up.railway.app/health
```

### Issue 2: Keychain Access Denied
**Symptoms:** "Failed to save tokens" in console
**Fix:** Check Xcode → Signing & Capabilities → Keychain Sharing

### Issue 3: State Not Updating
**Symptoms:** "Login successful" but UI doesn't change
**Fix:** Force UI update in `handleOAuthCallback`:

```swift
// After isAuthenticated = true, add:
await MainActor.run {
    self.isAuthenticated = true
    self.userEmail = email
}
```

### Issue 4: Wrong URL Scheme
**Symptoms:** OAuth completes but app doesn't open
**Fix:** Verify Info.plist has:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>inboxiq</string>
        </array>
    </dict>
</array>
```

---

## 📱 Quick Tests

### Test 1: Check if Token is Saved
Add temporary code to `LoginView.swift`:

```swift
Button("Check Keychain") {
    if let token = KeychainService.shared.getAccessToken() {
        print("✅ Token exists: \(token.prefix(20))...")
    } else {
        print("❌ No token in Keychain")
    }
}
```

### Test 2: Force Authentication State
Add temporary code to `LoginView.swift`:

```swift
Button("Force Login") {
    authViewModel.isAuthenticated = true
}
```

If this works but normal OAuth doesn't → OAuth callback issue.

### Test 3: Check Backend Redirect
After clicking "Sign in with Google", watch the browser redirect carefully:
- Does it redirect to Railway backend?
- Does Railway redirect back to `inboxiq://login?...`?
- Are parameters visible in the URL?

---

## 🔧 Debugging Checklist

**Before you start:**
- [ ] Backend is running (Railway health check passes)
- [ ] `Constants.swift` points to Railway (not localhost)
- [ ] Xcode console is visible (⇧⌘Y)
- [ ] Clean build completed (⇧⌘K then ⌘B)

**During test:**
- [ ] Click "Sign in with Google"
- [ ] Watch console for "OAuth callback received"
- [ ] Complete Google sign-in
- [ ] Watch for "Login successful" message
- [ ] Check if `isAuthenticated = true` appears
- [ ] Note any error messages

**After test:**
- [ ] Copy all console output
- [ ] Check if token exists in Keychain (Test 1)
- [ ] Check if forced login works (Test 2)
- [ ] Report findings to Shiv

---

## 📋 What to Send Me

If issue persists, copy and send:

1. **Console Output** (from Xcode bottom panel)
   - Everything from "OAuth callback received" onward
   - Include any error messages

2. **Backend Response** (if visible)
   - The final redirect URL (inboxiq://login?...)
   - All query parameters

3. **Behavior**
   - Does it loop immediately?
   - Does "Login successful" appear?
   - Does app restart or just refresh?

---

## 🚀 Expected Fix Timeline

**If backend issue:** 5-10 minutes (update backend route)
**If state issue:** 2-5 minutes (force MainActor update)
**If Keychain issue:** 5 minutes (add error handling)

---

## 💡 Pro Tip: Enable Debug Logging

In Xcode, go to:
- Product → Scheme → Edit Scheme
- Run → Arguments
- Add Environment Variable:
  - Name: `OS_ACTIVITY_MODE`
  - Value: `disable`

This reduces noise in console, making our logs easier to read.

---

**Next Step:** Clean build (⇧⌘K), run (⌘R), sign in, and **watch the console carefully**. Copy any errors you see and send them to me!
