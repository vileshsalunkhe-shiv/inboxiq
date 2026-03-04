# iOS Changes - Hybrid OAuth Flow Implementation
## Date: 2026-03-03

### Files Modified

#### 1. InboxIQ/Utils/Constants.swift
**Changes:**
- Updated OAuth configuration to use backend callback
- Changed `oauthCallbackScheme` from Google URL scheme to `inboxiq`
- Set `oauthClientId` to Web client ID (for backend token exchange)
- Added `oauthBackendCallbackURL` pointing to Railway backend

```swift
static let oauthCallbackScheme = "inboxiq"  // iOS app scheme for receiving tokens
static let oauthClientId = "535816296321-a722g108h5cqt6ai2v1c7jma0200ij36.apps.googleusercontent.com"  // Web client
static let oauthBackendCallbackURL = "\(apiBaseURL.absoluteString)/auth/ios/callback"
```

#### 2. InboxIQ/ViewModels/AuthViewModel.swift
**Changes:**
- Extract JWT tokens AND user_id from backend redirect (not auth code)
- Save `backend_user_id` to UserDefaults for API calls
- Simplified flow: backend handles all OAuth complexity

```swift
// Extract JWT tokens AND user_id from backend redirect
guard let accessToken = ...,
      let userId = UUID(uuidString: userIdString) else { ... }

// Save user_id to UserDefaults for API calls
UserDefaults.standard.set(userIdString, forKey: "backend_user_id")
```

#### 3. InboxIQ/ViewModels/CalendarAuthViewModel.swift
**Changes:**
- Added `getBackendUserId()` helper to fetch from UserDefaults
- Updated `checkStatus()` to use backend user_id (not CoreData local id)
- Updated `startAuth()` to use backend user_id
- Removed dependency on CoreData UserEntity for API calls

#### 4. InboxIQ/Views/Auth/LoginView.swift
**Changes:**
- Updated `buildAuthURL()` to use backend callback URL
- Changed `redirect_uri` to `Constants.oauthBackendCallbackURL`

```swift
URLQueryItem(name: "redirect_uri", value: Constants.oauthBackendCallbackURL)
```

#### 5. InboxIQ/InboxIQApp.swift
**Changes:**
- Added calendar check AFTER successful login
- Conditional calendar status check on app launch (only if authenticated)
- Prevents timing issues with user_id not being set yet

```swift
.onOpenURL { url in
    if isCalendarCallback(url) {
        // Handle calendar callback
    } else {
        await authViewModel.handleOAuthCallback(url)
        // After successful login, check calendar status
        if authViewModel.isAuthenticated {
            await calendarAuthViewModel.checkStatus(...)
        }
    }
}
```

#### 6. InboxIQ/Info.plist
**Changes:**
- Simplified URL schemes registration
- Removed Google URL scheme (no longer needed)
- Kept only `inboxiq` scheme for receiving JWT tokens

```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>inboxiq</string>
</array>
```

---

## Architecture Changes

### Before (Broken)
1. iOS → Google OAuth (gets code)
2. iOS → Tries to send code to backend
3. Backend → Fails (redirect_uri mismatch)

### After (Working) ✅
1. iOS → Opens OAuth pointing to **backend callback** (HTTPS)
2. User authorizes in Safari
3. Google → Redirects to **backend** with code
4. Backend → Exchanges code for Google tokens
5. Backend → Creates/finds user in database
6. Backend → Generates JWT tokens
7. Backend → Redirects to `inboxiq://login?access_token=...&user_id=...`
8. iOS → Intercepts URL, saves tokens + user_id
9. iOS → Authenticated! ✅

### Key Benefits
- ✅ Secure: Google tokens never leave backend
- ✅ Standard: Uses Web OAuth client (has secret)
- ✅ Simple: iOS just receives final JWT tokens
- ✅ Maintainable: Backend controls all OAuth logic

---

## Testing Notes

**Successful Flow:**
1. Login works with `vilesh.salunkhe@gmail.com`
2. Email sync: 11+ emails synced successfully
3. Calendar OAuth: Connected and working
4. User ID properly shared between login and calendar

**Railway Logs (Success):**
```
✅ ios_oauth_callback_received
✅ POST https://oauth2.googleapis.com/token "200 OK"
✅ GET https://www.googleapis.com/oauth2/v2/userinfo "200 OK"
✅ ios_oauth_callback_user_found
✅ ios_oauth_callback_success
✅ GET /calendar/status "200 OK"
✅ GET /calendar/auth/initiate "200 OK"
```

---

## Google Cloud Console Configuration

### Main OAuth (Web Client)
- **Client ID:** `535816296321-a722g108h5cqt6ai2v1c7jma0200ij36.apps.googleusercontent.com`
- **Redirect URIs:**
  - `https://inboxiq-production-5368.up.railway.app/auth/ios/callback` ✅

### Calendar OAuth (Web Client)
- **Client ID:** `380178868389-qr1tr2eg9k3kad03fb9srv8opnbnurm7.apps.googleusercontent.com`
- **Redirect URIs:**
  - `https://inboxiq-production-5368.up.railway.app/calendar/callback` ✅

---

**Status:** All iOS changes complete and tested successfully on Railway production! 🎉
