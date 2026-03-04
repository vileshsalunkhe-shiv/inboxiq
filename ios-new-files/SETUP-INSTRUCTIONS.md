# iOS OAuth Setup - Step by Step

All the Swift files you need are in this folder. Follow these steps IN ORDER:

---

## Step 1: Add Constants.swift

1. In Xcode, **right-click** on the **InboxIQ** folder (blue icon)
2. Select **New File...**
3. Choose **Swift File**
4. Name it: `Constants`
5. Click **Create**
6. **Open:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios-new-files/Constants.swift`
7. **Copy ALL the content** from that file
8. **Paste it** into your new Constants.swift file in Xcode
9. Save (⌘S)

---

## Step 2: Add AuthViewModel.swift

Same process:
1. **New File** > **Swift File** > Name: `AuthViewModel`
2. **Copy from:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios-new-files/AuthViewModel.swift`
3. **Paste** into Xcode
4. Save

---

## Step 3: Add OAuthWebView.swift

Same process:
1. **New File** > **Swift File** > Name: `OAuthWebView`
2. **Copy from:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios-new-files/OAuthWebView.swift`
3. **Paste** into Xcode
4. Save

---

## Step 4: Replace ContentView.swift

1. In Xcode, find **ContentView.swift** (should already exist)
2. **Select ALL the content** in that file and delete it
3. **Copy from:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios-new-files/ContentView.swift`
4. **Paste** into Xcode's ContentView.swift
5. Save

---

## Step 5: Update Info.plist

1. Find **Info.plist** in Xcode's left sidebar
2. **Right-click** on it → **Open As** → **Source Code**
3. Find this line near the top: `<dict>` (right after `<plist version="1.0">`)
4. **Copy the XML from:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios-new-files/Info-plist-additions.xml`
5. **Paste it RIGHT AFTER the `<dict>` line**
6. Save

Your Info.plist should now look like:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleURLTypes</key>
	<array>
		... (the XML you just pasted)
```

---

## Step 6: Build & Run

1. **Product** → **Clean Build Folder** (⇧⌘K)
2. Select a simulator (iPhone 15 or similar)
3. Click **Run** (⌘R) or press the Play button

---

## Step 7: Test OAuth

1. App should launch with "Sign in with Google" button
2. Tap the button
3. Google auth screen should appear in a web view
4. Sign in with your Google account
5. **Watch your Terminal** where the backend is running - you should see:
   ```
   INFO: POST /auth/login
   ```
6. If successful:
   - App shows "Login Successful! 🎉"
   - Your email appears
   - Backend logs show token exchange details

---

## Troubleshooting

**Build errors?**
- Make sure all 4 Swift files are added to the project
- Check that Info.plist XML is properly formatted (no missing `<` or `>`)

**No backend logs?**
- Verify backend is running: `curl http://localhost:8000/health`
- Check Constants.swift has `http://localhost:8000`

**OAuth error in app?**
- Error message will appear on screen
- Share it with Shiv for diagnosis

---

**Ready to test!** 🔥
