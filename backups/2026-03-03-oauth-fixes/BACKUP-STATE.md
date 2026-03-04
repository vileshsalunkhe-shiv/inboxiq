# Backup: OAuth Flow Fixes - 2026-03-03 20:11 CST

## Current State

**Status:** iOS calling backend, but token exchange failing

**Error:** `unauthorized_client` - Web client can't use iOS custom URL scheme redirect

**Progress:**
- ✅ iOS OAuth callback properly extracts auth code
- ✅ iOS calls `/auth/ios/login` endpoint with code
- ✅ Backend receives request and attempts token exchange
- ❌ Google rejects token exchange (redirect_uri mismatch)

## Issue

Web OAuth clients only accept http/https redirect URIs, not custom schemes like `com.googleusercontent.apps...`

iOS clients don't have secrets, so can't be used for backend token exchange.

## Solution (About to Implement)

**Hybrid OAuth Flow:**
1. iOS → Opens OAuth with backend redirect (`https://...railway.app/auth/ios/callback`)
2. Backend → Receives code, exchanges for tokens, creates user
3. Backend → Redirects to iOS app with JWT tokens (`inboxiq://login?access_token=...`)
4. iOS → Intercepts URL, saves tokens

## Backed Up Files

- `AuthViewModel.swift` - iOS OAuth callback handler
- `Constants.swift` - OAuth client ID and URLs
- `Info.plist` - URL scheme registration
- `auth_ios.py` - Backend iOS login endpoint

## Railway Logs (Last Successful Call)

```
INFO:app.api.auth_ios: ios_oauth_login_attempt code_prefix=4/0AfrIepAmtoEUBihYD
ERROR:app.services.auth_service: google_oauth_token_exchange_failed status_code=401
  error_detail: "unauthorized_client"
  client_id_prefix: 535816296321-a722g10
  redirect_uri: com.googleusercontent.apps.535816296321-0l834ob6tluso0d4hr8igp4ehe80mc4b:/oauth2redirect
```

## OAuth Credentials

**Web Client (in Railway env vars):**
- Client ID: `535816296321-a722g108h5cqt6ai2v1c7jma0200ij36.apps.googleusercontent.com`
- Has secret: Yes
- Redirect URIs: https only

**iOS Client (in iOS app):**
- Client ID: `535816296321-0l834ob6tluso0d4hr8igp4ehe80mc4b.apps.googleusercontent.com`
- Has secret: No (native iOS client)
- Bundle ID: `com.vss.InboxIQ`
- URL Scheme: `com.googleusercontent.apps.535816296321-0l834ob6tluso0d4hr8igp4ehe80mc4b`

## Next Steps

1. Create `/auth/ios/callback` endpoint (backend receives Google callback)
2. Backend exchanges code → creates user → generates JWT tokens
3. Backend redirects to `inboxiq://login?access_token=...&refresh_token=...`
4. Update iOS to handle token callback (not code callback)
5. Update Google Cloud Console Web client redirect URI to Railway callback

---

**Resume Point:** Implement hybrid flow with backend handling OAuth callback
