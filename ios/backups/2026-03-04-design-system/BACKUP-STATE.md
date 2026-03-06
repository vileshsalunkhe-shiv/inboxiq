# Backup State - Design System & Dark Mode (INB-25)
**Created:** 2026-03-04 22:29 CST
**Task:** INB-25 - Design system & dark mode implementation
**Agent:** DEV-MOBILE-premium

## What's Backed Up

**Full iOS UI state before design system implementation:**

### Directories:
- `Views/` - All current SwiftUI views
- `Utils/` - Helper files (Constants, Logger, CategoryColors)
- `Assets.xcassets/` - App icon, launch screen, color assets

### Current State:
- **Login:** Basic OAuth flow UI
- **Inbox:** Email list with category badges
- **Calendar:** Event list view
- **Settings:** Basic settings screen
- **Components:** CategoryBadge, EmptyStateView

### Key Files:
- `ContentView.swift` - Main tab navigation
- `Constants.swift` - API URLs, app constants
- `CategoryColors.swift` - Email category color definitions
- `Logger.swift` - Unified logging

## What Will Change

**DEV-MOBILE-premium will create/modify:**

### New Files (Design System):
1. `DesignSystem/Colors.swift` - Semantic color palette (light/dark mode)
2. `DesignSystem/Typography.swift` - Text styles (SF Pro fonts)
3. `DesignSystem/Spacing.swift` - 8pt grid system
4. `DesignSystem/Components/` - Reusable UI components
   - PrimaryButton.swift
   - SecondaryButton.swift
   - CardView.swift
   - SectionHeader.swift
   - LoadingView.swift
   - ErrorView.swift

### Modified Files (Dark Mode Support):
- All existing views in `Views/` directory
- `Assets.xcassets/` - Add dark mode color sets
- May update `CategoryColors.swift` with semantic colors

### Expected Additions:
- ~8-12 new files (design system components)
- Dark mode support in all existing views
- SF Symbols integration
- ClearPointLogic theme colors

## How to Restore (If Needed)

### Full Restore:
```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ/InboxIQ
rm -rf Views/ Utils/ Assets.xcassets/
cp -r /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/backups/2026-03-04-design-system/Views ./
cp -r /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/backups/2026-03-04-design-system/Utils ./
cp -r /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/backups/2026-03-04-design-system/Assets.xcassets ./
```

### Selective Restore (Single File):
```bash
cp /path/to/backup/file.swift /path/to/project/file.swift
```

### Verify Restore:
```bash
# Build project in Xcode
# Run on simulator
# Verify login, inbox, calendar tabs work
```

## Testing After Agent Completes

**Mandatory tests before integration:**

### 1. Build & Run:
- Clean build folder (⇧⌘K)
- Build project (⌘B) - should complete without errors
- Run on simulator (⌘R)

### 2. Light Mode Testing:
- Verify all screens display correctly
- Check new components render properly
- Ensure existing functionality works

### 3. Dark Mode Testing:
- Toggle dark mode (Settings → Appearance → Dark)
- OR: iPhone simulator → Appearance → Dark
- Verify all screens adapt correctly
- Check text contrast/readability
- Verify category colors are visible

### 4. Component Testing:
- Test new buttons (tap, disabled states)
- Test cards (expand/collapse if applicable)
- Test loading/error states
- Verify SF Symbols render correctly

### 5. Regression Testing:
- Login flow still works ✅
- Email list displays ✅
- Calendar events show ✅
- Settings accessible ✅

## Current Xcode Project State

**Project:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ/InboxIQ.xcodeproj`

**Bundle ID:** com.vss.InboxIQ
**iOS Target:** iOS 17+
**Language:** Swift
**Framework:** SwiftUI

**Current tabs:**
1. Home (Inbox)
2. Calendar
3. Settings

**Working features:**
- OAuth login (hybrid flow)
- Email sync and display
- AI categorization
- Calendar events
- App icon and launch screen

## Next Steps After Agent Completes

1. **Review output** - Check all new files created
2. **Read agent summary** - Understand changes made
3. **Test in Xcode** - Build and run (light + dark mode)
4. **If issues found:**
   - Minor: Fix manually
   - Major: Restore from backup, spawn new agent with fixes
5. **If tests pass:**
   - Commit to git
   - Update Linear (mark INB-25 Done)
   - Move to next iOS task

## Risk Assessment

**Risk Level:** LOW-MEDIUM

**Why Low:**
- Design system is additive (new files)
- Dark mode updates existing views but doesn't change logic
- No backend dependencies
- Easy to restore if issues arise

**Why Medium:**
- Touches many existing files
- Color changes could affect readability
- SF Symbols might not render on older iOS versions (but we target iOS 17+)

**Mitigation:**
- Full backup created ✅
- Thorough testing checklist ready ✅
- Restore procedure documented ✅

## Agent Instructions Summary

**Agent:** DEV-MOBILE-premium
**Task:** INB-25 - Design system & dark mode
**Deliverables:**
1. Design system files (Colors, Typography, Spacing, Components)
2. Dark mode support in all views
3. SF Symbols integration
4. ClearPointLogic theme implementation
5. Testing summary document

**Duration:** 2 days (estimate: 6-10 hours)

---

**Backup created:** 2026-03-04 22:29 CST
**Status:** Ready for agent spawn
**Approval:** V approved ("Let's do option 1")
