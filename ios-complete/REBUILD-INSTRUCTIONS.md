# InboxIQ iOS Rebuild Instructions

1. **Delete current test app**
   - Remove `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ/` from Xcode.

2. **Create a new Xcode project**
   - iOS App (SwiftUI)
   - Product Name: `InboxIQ`
   - Bundle ID: `com.inboxiq.ios`

3. **Add all files from the rebuilt source**
   - Drag everything inside:
     - `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios-complete/InboxIQ/`
   - Ensure folder groups match: `Views`, `ViewModels`, `Services`, `Models`, `Utils`, `CoreData`, `Extensions`.

4. **Update Info.plist**
   - Replace with:
     - `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios-complete/InboxIQ/Info.plist`
   - Required:
     - ATS exceptions for `localhost`
     - `CFBundleURLTypes` for `inboxiq`

5. **Build & Run**
   - Select a simulator or device
   - Build and run

6. **Test OAuth flow**
   - Tap “Sign in with Google”
   - Complete Google login
   - Verify login returns and user is authenticated

7. **Test email sync (if backend ready)**
   - Trigger sync from Home screen
   - Validate emails and categories load

If anything fails, confirm backend is running at `http://localhost:8000` and OAuth redirect URI is registered.
