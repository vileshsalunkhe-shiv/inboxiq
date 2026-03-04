# InboxIQ iOS – Google Calendar Integration

This folder contains the updated/added files needed to integrate Google Calendar into the existing InboxIQ iOS app.

## ✅ What’s Included
- Core Data model update (CalendarEventEntity + UserEntity.calendarConnected)
- Calendar API service
- Calendar OAuth view model
- Calendar list/detail/create views
- Updated ContentView + App bootstrapping
- Updated Constants + Info.plist

## 📁 Files Provided (copy into app)
```
InboxIQ/
  CoreData/
    PersistenceController.swift
    CalendarEntity+Extensions.swift
    InboxIQ.xcdatamodeld/InboxIQ.xcdatamodel/contents
  Models/
    CalendarEvent.swift
  Services/
    CalendarService.swift
  Utils/
    Constants.swift
  ViewModels/
    CalendarAuthViewModel.swift
    CalendarListViewModel.swift
  Views/
    ContentView.swift
    Calendar/
      CalendarConnectionView.swift
      CalendarListView.swift
      CalendarEventDetailView.swift
      CreateEventView.swift
  InboxIQApp.swift
  Info.plist
```

## 🧩 Step-by-step Integration

1. **Copy new/updated files**
   - Copy all files from this integration folder into your existing project directory:
     `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ/InboxIQ/`
   - Overwrite the existing files:
     - `InboxIQApp.swift`
     - `ContentView.swift`
     - `Constants.swift`
     - `PersistenceController.swift`
     - `Info.plist`

2. **Add files to Xcode project**
   - Open `InboxIQ.xcodeproj`
   - Drag the new files into the appropriate groups:
     - `Services/CalendarService.swift`
     - `ViewModels/CalendarAuthViewModel.swift`
     - `ViewModels/CalendarListViewModel.swift`
     - `Views/Calendar/*`
     - `Models/CalendarEvent.swift`
     - `CoreData/CalendarEntity+Extensions.swift`
   - Ensure “Copy items if needed” is checked.

3. **Update Core Data model**
   - In Xcode, open `InboxIQ.xcdatamodeld`
   - Add a new entity **CalendarEventEntity** with attributes:
     - `id` (UUID, non-optional)
     - `eventId` (String, non-optional)
     - `summary` (String, non-optional)
     - `eventDescription` (String, optional)
     - `startDate` (Date, non-optional)
     - `endDate` (Date, non-optional)
     - `location` (String, optional)
     - `htmlLink` (String, optional)
   - Add relationship:
     - `user` (to-one → UserEntity, inverse: `calendarEvents`, delete: Nullify)
   - Update **UserEntity**:
     - add `calendarConnected` (Boolean, default `false`)
     - add relationship `calendarEvents` (to-many → CalendarEventEntity, inverse: `user`, delete: Cascade)

   **Note:** We used `eventDescription` to avoid a clash with NSObject’s `description` property.

4. **Update URL scheme**
   - Ensure `Info.plist` includes the `inboxiq` URL scheme (already in the updated file).
   - Calendar OAuth callback is `inboxiq://calendar/callback`.

5. **Configure backend base URL**
   - Update `Constants.apiBaseURL` for production:
     - `https://inboxiq-production-5368.up.railway.app`

6. **Run & test**
   - Launch app, sign in, open the **Calendar** tab.
   - Tap **Connect Calendar**.
   - OAuth should redirect back to the app via `inboxiq://calendar/callback`.
   - Pull to refresh, create new events, and verify they appear.

## ⚠️ Important Note on `user_id`
Calendar endpoints require `user_id` (UUID). Current integration uses `UserEntity.id` from Core Data. If your backend expects a different UUID (e.g., from auth login response), store that value in UserEntity and update CalendarService to use it.

## ✅ Backend Endpoints Used
- `GET /calendar/auth/initiate?user_id=<UUID>`
- `GET /calendar/callback?code=<code>&state=<state>`
- `GET /calendar/status?user_id=<UUID>`
- `GET /calendar/events?user_id=<UUID>&max_results=10`
- `POST /calendar/events?user_id=<UUID>`

---
If you want, I can also provide a migration for an existing Core Data store or assist with a backend user_id strategy.
