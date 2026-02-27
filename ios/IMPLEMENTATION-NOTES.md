# InboxIQ iOS Foundation — Implementation Notes

## What I Built
A complete SwiftUI + Core Data foundation for InboxIQ, aligned to the architecture doc. The app includes:
- OAuth 2.0 login flow using `ASWebAuthenticationSession`
- Secure token storage via Keychain (access-group aware)
- Async/await API client with auto-refresh on 401 (guarded against refresh loops)
- Sync service + Core Data merge strategy
- SwiftUI views for login, home, email list/detail, and settings
- Background fetch + silent push hooks

## Project Structure
```
InboxIQ/
├── InboxIQApp.swift
├── Models/
├── ViewModels/
├── Views/
├── Services/
├── CoreData/
├── Extensions/
└── Utils/
```

## Setup Instructions (Xcode 15+, iOS 17+)
1. Create a new Xcode iOS App project named **InboxIQ**.
2. Copy the contents of `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ/` into the project’s source folder.
3. Add `InboxIQ/CoreData/InboxIQ.xcdatamodeld` as an existing file (File > Add Files to “InboxIQ…”).
4. Replace the project’s Info.plist with `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/Info.plist`.
5. Add `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/Entitlements.plist` to the target and enable:
   - Push Notifications
   - Background Modes: **fetch**, **remote-notification**
   - Keychain Sharing: `$(AppIdentifierPrefix)com.inboxiq.shared`
6. Add URL Scheme in **Info > URL Types**:
   - `inboxiq` (matches `Constants.oauthCallbackScheme`)
7. Update in `Constants.swift`:
   - `Constants.oauthClientId`
   - `Constants.apiBaseURL`
8. Ensure Bundle Identifier matches entitlements (e.g., `com.inboxiq.ios`).

### Build Settings Needed
- Deployment target: iOS 17.0
- Enable Background Modes (fetch + remote notifications)
- Enable Push Notifications capability
- Keychain Sharing capability with the specified access group

### Notes on Keychain Access Groups
`KeychainService` automatically ignores placeholder access-group strings (e.g., `$(AppIdentifierPrefix)…`) at runtime to avoid simulator failures. For device builds, the access group must match the app’s entitlements.

## Core Data Model
Entities (with relationships):
- **EmailEntity**: id, gmailId, subject, sender, snippet, receivedAt, syncedAt, isUnread, category
- **CategoryEntity**: id, name, color, icon, count, emails (inverse of email.category)
- **UserEntity**: id, email, lastSyncDate, emails

Merge policy: `NSMergeByPropertyObjectTrumpMergePolicy`. Context auto-merges background changes.

## API Client
- Async/await throughout
- 401 refresh guarded so it never loops on `/auth/refresh`
- Empty responses handled for logout endpoints
- Errors surfaced as `AppError` and displayed in views

## Testing Approach
- Unit tests for APIClient + AuthService (mock URLSession)
- Core Data tests using in-memory store
- UI tests for OAuth entry flow + list filters

## Next Steps (Phase 2)
- Implement real backend endpoints + DTO mapping
- Add category management UI
- Implement push token registration
- Full background sync behavior (silent push triggers)
- Add Sentry iOS integration
