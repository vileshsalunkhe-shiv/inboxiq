# iOS App Deployment Guide

## Overview

Last night (2026-03-01) we completed the full InboxIQ iOS app with:
- ✅ Complete OAuth flow (ASWebAuthenticationSession)
- ✅ Email sync and display (50+ emails working)
- ✅ Token refresh automatic retry
- ✅ CoreData persistence
- ✅ SwiftUI interface (Auth, Home, Email List, Detail, Settings)

**Current Status:** App is fully functional in Simulator, ready for device testing and TestFlight.

---

## iOS App Location

**Complete app structure:**
```
/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ/
```

**Key components:**
- Xcode project: `InboxIQ.xcodeproj`
- App source: `InboxIQ/` (30+ Swift files)
- CoreData: `InboxIQ/CoreData/`
- Assets: `InboxIQ/Assets.xcassets/`
- Info.plist (with ATS exceptions, URL schemes)

---

## Deployment Options

### Option 1: TestFlight Beta Testing (Recommended)

**Best for:**
- Testing with real devices
- Sharing with team/beta testers
- Pre-production validation

**Requirements:**
- Apple Developer Account ($99/year)
- App provisioning profiles
- TestFlight setup in App Store Connect

**Steps:**

#### 1. Apple Developer Account Setup
- Enroll at: https://developer.apple.com/programs/enroll/
- Wait for approval (usually 24-48 hours)
- Cost: $99/year

#### 2. Configure App Identifiers
1. Go to: https://developer.apple.com/account/resources/identifiers/list
2. Click "+" to create new identifier
3. Select "App IDs" → "App"
4. Description: "InboxIQ"
5. Bundle ID: `com.vss.InboxIQ` (explicit)
6. Capabilities (check):
   - Push Notifications
   - Background Modes (Background fetch, Remote notifications)
7. Click "Continue" → "Register"

#### 3. Create Provisioning Profiles
1. Go to: https://developer.apple.com/account/resources/profiles/list
2. Click "+" to create profile
3. Select "App Store" distribution
4. App ID: Select "InboxIQ"
5. Certificate: Create/select distribution certificate
6. Name: "InboxIQ Distribution"
7. Download and double-click to install in Xcode

#### 4. Configure Xcode Project
1. Open Xcode project: `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ/InboxIQ.xcodeproj`
2. Select target "InboxIQ"
3. Go to "Signing & Capabilities"
4. Team: Select your Apple Developer team
5. Bundle Identifier: `com.vss.InboxIQ`
6. Signing: Automatic
7. Provisioning Profile: Select "InboxIQ Distribution"

#### 5. Archive and Upload to TestFlight
1. In Xcode: Product → Archive
2. Wait for archive to complete
3. Organizer window opens → Select archive
4. Click "Distribute App"
5. Select "App Store Connect"
6. Upload → Next → Upload
7. Wait for processing (15-30 minutes)

#### 6. TestFlight Setup
1. Go to: https://appstoreconnect.apple.com
2. My Apps → InboxIQ → TestFlight
3. Add internal testers (email addresses)
4. Enable "Automatically notify testers"
5. Submit for review (first build only)
6. Wait for approval (usually 24 hours)
7. Testers receive email with TestFlight link

---

### Option 2: Direct Device Installation (Development)

**Best for:**
- Quick testing on your own device
- No App Store submission needed
- Immediate deployment

**Requirements:**
- Apple Developer Account (free or paid)
- USB cable to connect device
- Trust your Mac on device

**Steps:**

#### 1. Configure Free Development
1. Open Xcode project
2. Go to "Signing & Capabilities"
3. Team: Add your Apple ID (free account works)
4. Bundle Identifier: Change to unique ID (e.g., `com.yourname.InboxIQ`)
5. Signing: Automatic
6. Xcode will create development profile automatically

#### 2. Connect Device
1. Connect iPhone via USB
2. Unlock device
3. Trust this computer (prompt on device)
4. In Xcode: Select your device from device menu (top bar)

#### 3. Build and Run
1. In Xcode: Product → Run (⌘R)
2. App installs on device
3. If "Untrusted Developer" error:
   - Settings → General → VPN & Device Management
   - Trust your developer profile
4. Launch app from home screen

**Limitations:**
- 7-day expiry (need to re-sign weekly with free account)
- Limited to 3 devices
- No TestFlight distribution

---

### Option 3: Ad Hoc Distribution

**Best for:**
- Distributing to specific devices (up to 100)
- No TestFlight needed
- Longer validity than development

**Steps:**

#### 1. Register Devices
1. Get UDIDs from testers' devices
2. Add in Apple Developer: Devices → "+"
3. Name and UDID for each device

#### 2. Create Ad Hoc Profile
1. Certificates, Identifiers & Profiles → Profiles
2. "+" → Ad Hoc
3. Select App ID: InboxIQ
4. Select devices to include
5. Download and install

#### 3. Archive with Ad Hoc Profile
1. Xcode: Select Ad Hoc provisioning
2. Product → Archive
3. Distribute App → Ad Hoc
4. Export IPA file
5. Distribute IPA to testers (via email, web, etc.)

#### 4. Install on Devices
- Use Apple Configurator 2, Diawi, or TestFlight alternative

---

## Backend Configuration for iOS

### Current Backend URLs

**Local Testing:**
```swift
// Constants.swift
static let baseURL = "http://localhost:8000"
```

**Production (Railway):**
```swift
// Constants.swift
static let baseURL = "https://inboxiq-production-5368.up.railway.app"
```

### OAuth Configuration

**Google OAuth Credentials:**
- Client ID: Already configured in `.env`
- Redirect URI scheme: `inboxiq://oauth/callback`
- Google Cloud Console: Add redirect URI for iOS

**Steps:**
1. Go to: https://console.cloud.google.com/apis/credentials
2. Edit OAuth 2.0 Client (Web application)
3. Authorized redirect URIs → Add:
   ```
   inboxiq://oauth/callback
   ```
4. Save

---

## Pre-Deployment Checklist

### Code Verification
- [ ] Update `Constants.swift` with production backend URL
- [ ] Verify bundle identifier: `com.vss.InboxIQ`
- [ ] Check Info.plist has required permissions:
  - [ ] NSAppTransportSecurity (for HTTP localhost testing)
  - [ ] URL Schemes: `inboxiq`
- [ ] Remove any hardcoded test credentials

### Assets
- [ ] App icon set (1024x1024 for App Store)
- [ ] Launch screen configured
- [ ] All required image assets present

### Testing
- [ ] OAuth flow works on device
- [ ] Email sync successful
- [ ] Email display working
- [ ] Token refresh automatic
- [ ] Background refresh enabled
- [ ] Push notifications configured (future)

### Compliance
- [ ] Privacy Policy URL in App Store Connect
- [ ] Terms of Service URL
- [ ] Data collection disclosure
- [ ] Export compliance (App Store submission)

---

## Post-Deployment

### Monitor
- TestFlight feedback
- Crash reports (Xcode Organizer → Crashes)
- User feedback
- Backend logs for mobile requests

### Iterate
- Fix bugs discovered in testing
- Add features from roadmap
- Update backend APIs as needed
- Submit new builds to TestFlight

---

## Recommended Next Steps

**For immediate testing:**
1. ✅ **Option 2 (Direct Device)** - Quick setup, test on your iPhone today
2. Update `Constants.swift` to point to Railway backend
3. Build and run on your device
4. Test OAuth, email sync, display

**For team/beta testing:**
1. ✅ **Option 1 (TestFlight)** - Professional distribution
2. Submit first build this week
3. Add internal testers (team members)
4. Get feedback, iterate
5. Launch to external testers when ready

**For production:**
1. Complete TestFlight beta testing
2. Polish UI/UX based on feedback
3. Submit to App Store review
4. Launch publicly 🚀

---

## Files Created Last Night

**Location:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ/`

**Key files:**
- `InboxIQApp.swift` - App entry point
- `ContentView.swift` - Main navigation
- `AuthViewModel.swift` - OAuth logic
- `SyncService.swift` - Email sync
- `EmailListView.swift` - Email display
- `CoreData/InboxIQ.xcdatamodeld` - Data model
- `Info.plist` - App configuration

**Total:** 30+ Swift files, fully functional iOS app

---

**Created:** 2026-03-02 22:35 CST  
**Status:** Ready for device testing 🚀  
**Next:** Deploy to your iPhone and test with Railway backend!
