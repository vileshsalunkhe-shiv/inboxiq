# iOS Pagination Task Specification

## Goal
Add "Load More" functionality for emails and calendar events to allow users to access data beyond the initial 7-day windows.

## Context
- **Backend API:** Pagination endpoints implemented (see BACKEND-PAGINATION-SPEC.md)
- **Current behavior:** Shows only last 7 days of emails, next 7 days of calendar
- **Linear issue:** INB-21
- **Project location:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ/`

---

## Task 1: Email Pagination

### Current Implementation
**File:** `EmailListViewModel.swift`
- Fetches emails via `SyncService.shared.sync(context:)`
- Displays all synced emails from CoreData

### Required Changes

**1. Add pagination state to EmailListViewModel:**
```swift
@Published var isLoadingMore: Bool = false
@Published var hasMoreEmails: Bool = false
@Published var nextPageToken: String? = nil
```

**2. Update SyncService to support pagination:**

**File:** `Services/SyncService.swift`

Add method:
```swift
func loadMoreEmails(pageToken: String, context: NSManagedObjectContext) async throws -> (hasMore: Bool, nextToken: String?)
```

Call backend:
```swift
GET /emails?user_id={uuid}&page_token={token}&max_results=50
```

**Backend response format:**
```swift
struct EmailPaginationResponse: Decodable {
    let emails: [EmailPayload]
    let nextPageToken: String?
    let hasMore: Bool
    let totalFetched: Int
    
    enum CodingKeys: String, CodingKey {
        case emails
        case nextPageToken = "next_page_token"
        case hasMore = "has_more"
        case totalFetched = "total_fetched"
    }
}
```

**3. Update EmailListView UI:**

**File:** `Views/Home/EmailListView.swift`

Add "Load More" button at bottom:
```swift
if viewModel.hasMoreEmails {
    Button(action: {
        Task {
            await viewModel.loadMoreEmails(context: viewContext)
        }
    }) {
        HStack {
            if viewModel.isLoadingMore {
                ProgressView()
                    .padding(.trailing, 8)
            }
            Text(viewModel.isLoadingMore ? "Loading..." : "Load More Emails")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    .padding(.horizontal)
    .padding(.bottom)
    .disabled(viewModel.isLoadingMore)
}
```

**4. Handle scroll to bottom (alternative/future):**
```swift
// Optional: Detect scroll to bottom for auto-load
// Can be added later if user prefers
```

---

## Task 2: Calendar Pagination

### Current Implementation
**File:** `CalendarListViewModel.swift`
- Fetches events via `CalendarService.shared.syncCalendar(context:)`
- Shows next 7 days only

### Required Changes

**1. Add pagination state to CalendarListViewModel:**
```swift
@Published var isLoadingEarlier: Bool = false
@Published var isLoadingLater: Bool = false
@Published var earliestDate: Date = Date()
@Published var latestDate: Date = Date().addingTimeInterval(7 * 24 * 3600)
```

**2. Update CalendarService to support time ranges:**

**File:** `Services/CalendarService.swift`

Add method:
```swift
func fetchEvents(userId: UUID, timeMin: Date, timeMax: Date, maxResults: Int = 10) async throws -> [CalendarEventPayload]
```

Call backend:
```swift
GET /calendar/events?user_id={uuid}&time_min={iso8601}&time_max={iso8601}&max_results=10
```

**3. Update CalendarListView UI:**

**File:** `Views/Calendar/CalendarListView.swift`

Add buttons at top and bottom:
```swift
// At top of list (past events)
Button(action: {
    Task {
        await viewModel.loadEarlierEvents(context: viewContext)
    }
}) {
    HStack {
        if viewModel.isLoadingEarlier {
            ProgressView()
                .padding(.trailing, 8)
        }
        Image(systemName: "arrow.up")
        Text("Load Earlier Events")
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(Color.secondary.opacity(0.1))
    .cornerRadius(8)
}
.padding(.horizontal)
.padding(.top)
.disabled(viewModel.isLoadingEarlier)

// ... existing list ...

// At bottom of list (future events)
Button(action: {
    Task {
        await viewModel.loadLaterEvents(context: viewContext)
    }
}) {
    HStack {
        if viewModel.isLoadingLater {
            ProgressView()
                .padding(.trailing, 8)
        }
        Text("Load Later Events")
        Image(systemName: "arrow.down")
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(Color.secondary.opacity(0.1))
    .cornerRadius(8)
}
.padding(.horizontal)
.padding(.bottom)
.disabled(viewModel.isLoadingLater)
```

**4. Implement load methods in CalendarListViewModel:**
```swift
func loadEarlierEvents(context: NSManagedObjectContext) async {
    isLoadingEarlier = true
    defer { isLoadingEarlier = false }
    
    let newMin = earliestDate.addingTimeInterval(-7 * 24 * 3600)  // 7 days earlier
    let newMax = earliestDate
    
    // Fetch and save to CoreData
    // Update earliestDate
}

func loadLaterEvents(context: NSManagedObjectContext) async {
    isLoadingLater = true
    defer { isLoadingLater = false }
    
    let newMin = latestDate
    let newMax = latestDate.addingTimeInterval(7 * 24 * 3600)  // 7 days later
    
    // Fetch and save to CoreData
    // Update latestDate
}
```

---

## User Experience

### Email Pagination
1. User scrolls to bottom of email list
2. Sees "Load More Emails" button
3. Taps button → shows "Loading..." with spinner
4. New emails append to bottom of list
5. Button disappears when no more emails (`hasMore: false`)

### Calendar Pagination
1. **Past events:** User taps "Load Earlier Events" at top → loads 7 more days into the past
2. **Future events:** User taps "Load Later Events" at bottom → loads 7 more days into the future
3. Loading indicators show during fetch
4. Events insert/append smoothly (no UI jumps)

---

## API Contracts (Reference)

### Email Pagination Response
```swift
struct EmailPaginationResponse: Decodable {
    let emails: [EmailPayload]
    let nextPageToken: String?
    let hasMore: Bool
    let totalFetched: Int
}
```

### Calendar Events Response (unchanged)
```swift
typealias CalendarEventPayload  // Already defined, no changes needed
```

---

## Files to Modify

1. **Services:**
   - `Services/SyncService.swift` - Add `loadMoreEmails()` method
   - `Services/CalendarService.swift` - Add time range parameters to `fetchEvents()`

2. **ViewModels:**
   - `ViewModels/EmailListViewModel.swift` - Add pagination state + `loadMoreEmails()` method
   - `ViewModels/CalendarListViewModel.swift` - Add pagination state + `loadEarlier/Later()` methods

3. **Views:**
   - `Views/Home/EmailListView.swift` - Add "Load More" button at bottom
   - `Views/Calendar/CalendarListView.swift` - Add "Load Earlier/Later" buttons

---

## Testing Checklist

### Email Pagination
- ✅ "Load More" button appears after initial sync
- ✅ Button shows loading state when tapped
- ✅ New emails append to bottom of list
- ✅ Button disappears when no more emails
- ✅ Error handling (network failures)

### Calendar Pagination
- ✅ "Load Earlier" button loads past events
- ✅ "Load Later" button loads future events
- ✅ Events insert/append without jumps
- ✅ Date range expands correctly (7-day chunks)
- ✅ Loading indicators work
- ✅ Error handling

---

## Notes
- **Preserve existing behavior:** Initial sync still loads last 7 days (emails) / next 7 days (calendar)
- **Smooth UX:** Use loading indicators, disable buttons during fetch
- **Empty states:** Show helpful message when no more data
- **Error handling:** Show alerts for network failures
- **No breaking changes:** Existing views continue to work

---

**Estimated time:** 2-3 hours
**Agent:** DEV-MOBILE-premium (GPT-5.2-Codex)
**Dependencies:** Backend pagination must be complete first
