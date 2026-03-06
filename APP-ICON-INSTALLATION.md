# InboxIQ App Icon - Installation Guide
**Final Icon:** `inboxiq-app-icon.png` (Version 7)
**Created:** 2026-03-04 22:12 CST
**Status:** ✅ APPROVED by V

## Design Summary
- **Style:** Envelope shape with gradient background
- **Colors:** Deep purple (#7C3AED), royal blue (#2563EB), vibrant magenta (#DB2777), bright orange (#EA580C)
- **Text:** White italic "IQ" with horizontal striped effect
- **Size:** 1024×1024 px (App Store requirement)

## Installation Steps (Xcode)

### Step 1: Open Xcode Project
```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ
open InboxIQ.xcodeproj
```

### Step 2: Navigate to App Icon Asset
1. In Xcode left sidebar, expand **InboxIQ** folder
2. Click **Assets.xcassets**
3. Click **AppIcon** in the asset list

### Step 3: Add the Icon
1. Locate the final icon file:
   ```
   /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/assets/inboxiq-app-icon.png
   ```
2. Drag `inboxiq-app-icon.png` to the **1024×1024** slot (labeled "App Store iOS")
3. Xcode will automatically generate all required sizes:
   - 20pt (40×40, 60×60)
   - 29pt (58×58, 87×87)
   - 40pt (80×80, 120×120)
   - 60pt (120×120, 180×180)

### Step 4: Verify
1. In Xcode, check that all icon slots are filled
2. Build the project (⌘B)
3. Run on simulator (⌘R)
4. Check home screen - icon should appear

### Step 5: Test on Device (Optional)
1. Connect iPhone via USB
2. Select device as target
3. Build and run
4. Check icon on device home screen

## Files
- **Production icon:** `/projects/inboxiq/assets/inboxiq-app-icon.png` (451KB)
- **All versions:** `/projects/inboxiq/assets/` (7 iterations saved)

## Design Iterations (History)
1. **V1:** Vibrant mesh gradient + bold IQ
2. **V2:** Envelope shape + muted gradient + modern IQ
3. **V3:** Italic + line-based letters + wider spacing
4. **V4:** Narrower letters + V2 colors
5. **V5:** Darker colors (deep purple/blue/magenta/orange)
6. **V6:** Muted colors + larger letters + black/white stripes (rejected)
7. **V7:** V5 style + slightly larger text ✅ **FINAL**

## Next Steps
1. ✅ Icon approved
2. [ ] Add to Xcode (follow steps above)
3. [ ] Build and test
4. [ ] Create launch screen (INB-31)
5. [ ] App Store submission

## Linear Issue
- **INB-31:** App icon & launch screen integration (0.5 day)
- **Status:** Icon complete, ready for Xcode integration

---

**Approved by:** V (2026-03-04 22:12 CST)
**Next:** Add to Xcode and create launch screen
