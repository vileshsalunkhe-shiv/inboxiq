# OAuth Integration Notes

## Working Configuration (Verified)
- **Redirect URI:** `http://localhost:8000/auth/google/callback`
- **Callback Scheme:** `http`
- **OAuth UI:** `ASWebAuthenticationSession` (Google blocks WKWebView)
- **Backend Exchange:** `POST /auth/login` with JSON body `{ "code": "..." }`

## Key Files
- `Utils/Constants.swift`
  - `apiBaseURL = http://localhost:8000`
  - `oauthCallbackScheme = "http"`
  - `oauthCallbackURL = "http://localhost:8000/auth/google/callback"`
- `Views/Auth/OAuthWebView.swift`
  - Uses `ASWebAuthenticationSession` for the Safari auth sheet
- `ViewModels/AuthViewModel.swift`
  - Extracts `code` from callback URL
  - Posts to `/auth/login`
  - Parses `accessToken`, `refreshToken`, `userEmail`
  - Saves tokens to Keychain

## Notes
- Login UI is in `Views/Auth/LoginView.swift`.
- `LoginView` includes `redirect_uri` in Google auth URL.
- `AuthService` and `APIClient` handle refresh/logout using stored tokens.
