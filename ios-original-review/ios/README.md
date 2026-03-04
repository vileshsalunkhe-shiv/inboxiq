# InboxIQ iOS

This folder contains the SwiftUI iOS app foundation for InboxIQ.

## What’s Included
- SwiftUI MVVM app structure
- Core Data model + persistence
- OAuth login flow using `ASWebAuthenticationSession`
- Keychain token storage
- Async/await API client with refresh handling
- Sync service skeleton for email pulls
- SwiftUI views for Login, Home, Email Detail, and Settings

## Requirements
- Xcode 15+ (recommended)
- iOS 17+ deployment target

## Setup (Xcode)
1. Create a new **iOS App** project named `InboxIQ`.
2. Replace the generated sources with the contents of `InboxIQ/` from this directory.
3. Add the Core Data model:
   - In Xcode, add existing file `InboxIQ/CoreData/InboxIQ.xcdatamodeld`.
4. Set **Bundle Identifier** to `com.inboxiq.app`.
5. Add **Info.plist** and **Entitlements.plist** from the root of this folder.
6. Enable **Background Modes**: `Background fetch` and `Remote notifications`.
7. Enable **Push Notifications** capability.
8. Add **Keychain Sharing** capability with access group:
   - `$(AppIdentifierPrefix)com.inboxiq.shared`

## Notes
- Update `Constants.oauthClientId` with your Google OAuth client ID.
- Update `Constants.apiBaseURL` to match your backend.
- OAuth callback scheme is `inboxiq://oauth/callback`.

## Build
Select a simulator or device and run. Login will launch OAuth via `ASWebAuthenticationSession`.
