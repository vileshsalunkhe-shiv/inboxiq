# 🚀 Quick Start: Add Calendar to InboxIQ iOS

## Run the Automated Script

**One command to copy all files:**

```bash
/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios-calendar-integration/integrate-calendar.sh
```

**What it does:**
- ✅ Creates backup of existing project
- ✅ Copies 13 calendar files to project directory
- ✅ Updates shared files (ContentView, Constants, Info.plist)
- ✅ Sets proper permissions
- ✅ Shows next steps

---

## After Script Runs - Xcode Steps (5 minutes)

### 1. Open Xcode
```bash
open /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ/InboxIQ.xcodeproj
```

### 2. Add New Files to Project

**Right-click "InboxIQ" folder → "Add Files to InboxIQ..."**

Select these NEW files:
- `Services/CalendarService.swift`
- `ViewModels/CalendarAuthViewModel.swift`
- `ViewModels/CalendarListViewModel.swift`
- `Views/Calendar/CalendarConnectionView.swift`
- `Views/Calendar/CalendarListView.swift`
- `Views/Calendar/CalendarEventDetailView.swift`
- `Views/Calendar/CreateEventView.swift`
- `Models/CalendarEvent.swift`
- `CoreData/CalendarEntity+Extensions.swift`

✅ Check **"Copy items if needed"**  
Click **"Add"**

### 3. Update CoreData Model

**Open `InboxIQ.xcdatamodeld` in Xcode**

#### Add NEW Entity: CalendarEventEntity

**Attributes:**
| Name | Type | Optional | Default |
|------|------|----------|---------|
| id | UUID | ❌ No | - |
| eventId | String | ❌ No | - |
| summary | String | ❌ No | - |
| eventDescription | String | ✅ Yes | - |
| startDate | Date | ❌ No | - |
| endDate | Date | ❌ No | - |
| location | String | ✅ Yes | - |
| htmlLink | String | ✅ Yes | - |

**Relationships:**
| Name | Destination | Type | Inverse | Delete Rule |
|------|-------------|------|---------|-------------|
| user | UserEntity | To One | calendarEvents | Nullify |

#### Update EXISTING Entity: UserEntity

**Add Attribute:**
| Name | Type | Optional | Default |
|------|------|----------|---------|
| calendarConnected | Boolean | ❌ No | false |

**Add Relationship:**
| Name | Destination | Type | Inverse | Delete Rule |
|------|-------------|------|---------|-------------|
| calendarEvents | CalendarEventEntity | To Many | user | Cascade |

### 4. Update Backend URL (Production)

**Open `Utils/Constants.swift`**

Change:
```swift
static let apiBaseURL = "http://localhost:8000"
```

To:
```swift
static let apiBaseURL = "https://inboxiq-production-5368.up.railway.app"
```

### 5. Build & Test

1. **Product → Clean Build Folder** (⇧⌘K)
2. **Product → Build** (⌘B)
3. Fix any errors (should compile cleanly)
4. **Product → Run** (⌘R)
5. Test Calendar tab:
   - Tap "Calendar" tab
   - Tap "Connect Calendar"
   - OAuth should open Safari
   - Authorize with Google
   - App should receive callback
   - Events should appear

---

## 🎉 Done!

Your iOS app now has Google Calendar integration:
- ✅ Calendar OAuth (separate from email)
- ✅ Event list view
- ✅ Event detail view
- ✅ Create event form
- ✅ Pull-to-refresh sync
- ✅ CoreData persistence

**Backend:** Already deployed to Railway  
**iOS:** Ready to test on device/simulator

---

## Troubleshooting

**Build errors?**
- Ensure all new files were added to Xcode project (target membership)
- Check CoreData model has both entities configured
- Clean build folder (⇧⌘K) and rebuild

**OAuth not working?**
- Check Info.plist has `inboxiq` URL scheme
- Verify Constants.apiBaseURL points to Railway
- Check backend logs for OAuth errors

**Events not appearing?**
- Pull down to refresh
- Check backend `/calendar/status` returns `connected: true`
- Verify CoreData entities are configured correctly

---

**Full details:** `CALENDAR-IOS-INTEGRATION.md`
