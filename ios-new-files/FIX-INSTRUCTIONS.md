# OAuth Fix - Use ASWebAuthenticationSession

## Problem
Google blocks OAuth in embedded web views (WKWebView) → Error 403: disallowed_useragent

## Solution
Use `ASWebAuthenticationSession` - Apple's official OAuth API

---

## Step 1: Replace OAuthWebView.swift

In Xcode, open `OAuthWebView.swift` and **replace ALL content** with:

**File:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios-new-files/OAuthWebView-FIXED.swift`

(Copy the entire file content)

---

## Step 2: Update Constants.swift

In Xcode, open `Constants.swift` and **replace ALL content** with:

**File:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios-new-files/Constants-FIXED.swift`

(Copy the entire file content)

**Key change:** `oauthCallbackScheme = "http"` (was "inboxiq")

---

## Step 3: Update AuthViewModel.swift (Optional - already correct)

If needed, verify `AuthViewModel.swift` matches:

**File:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios-new-files/AuthViewModel-FIXED.swift`

---

## Step 4: Clean Build & Run

1. **Product** → **Clean Build Folder** (⇧⌘K)
2. **Run** (⌘R)
3. Tap "Sign in with Google"

---

## What Will Happen

1. iOS opens **Safari authentication sheet** (not embedded web view)
2. You authenticate with Google
3. Google redirects to `http://localhost:8000/auth/google/callback?code=...`
4. iOS intercepts the callback
5. iOS extracts code and sends to backend `/auth/login`
6. Backend exchanges code for tokens
7. App shows "Login Successful!" 🎉

---

## Backend Status

✅ Backend fix applied (`auth_ios.py` imports corrected)  
✅ Server should restart automatically  
✅ `/auth/login` endpoint ready

---

**This should work!** The authentication will happen in Safari (secure) instead of WKWebView (blocked).
