# Deployment Guide (Local → Railway)

## 1) Update API Base URL
In `Utils/Constants.swift`:
```swift
static let apiBaseURL = URL(string: "https://YOUR-RAILWAY-URL")!
```

## 2) Update OAuth Redirect URI
- Update Google Cloud Console OAuth credentials:
  - Authorized redirect URI should match backend callback
- Update backend to use the production callback:
  - Example: `https://YOUR-RAILWAY-URL/auth/google/callback`
- Update `Constants.oauthCallbackURL` to the production callback

## 3) App Transport Security (ATS)
- If your Railway backend uses HTTPS (recommended), you can remove ATS exceptions for `localhost`.
- Keep ATS exceptions only for local development.

## 4) Test in Production
- Build and run on device
- Verify OAuth login completes in `ASWebAuthenticationSession`
- Confirm `/emails` and `/categories` load successfully

## 5) Optional: Environment Switching
Consider using build configs or `.xcconfig` files for `LOCAL` vs `PROD` values.
