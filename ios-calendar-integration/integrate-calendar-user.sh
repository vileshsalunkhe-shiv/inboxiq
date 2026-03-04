#!/bin/bash
# InboxIQ - Calendar Integration (User Version)
# Run as: vileshsalunkhe_mc

set -e

echo "🚀 InboxIQ Calendar Integration Script"
echo "======================================="
echo ""

# Paths
INTEGRATION_DIR="/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios-calendar-integration"
TARGET_DIR="/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ/InboxIQ"
XCODE_PROJECT="/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ/InboxIQ.xcodeproj"

# Check if target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ Error: Target directory not found: $TARGET_DIR"
    exit 1
fi

echo "📁 Source: $INTEGRATION_DIR/InboxIQ/"
echo "📁 Target: $TARGET_DIR/"
echo ""

# Create directory structure if missing
echo "📂 Ensuring directory structure..."
mkdir -p "$TARGET_DIR/Services"
mkdir -p "$TARGET_DIR/ViewModels"
mkdir -p "$TARGET_DIR/Views/Calendar"
mkdir -p "$TARGET_DIR/Models"
mkdir -p "$TARGET_DIR/CoreData"
mkdir -p "$TARGET_DIR/Utils"
echo "✅ Directories ready"
echo ""

# Copy files with permissions
echo "📋 Copying calendar integration files..."

# Copy Services
if [ -f "$INTEGRATION_DIR/InboxIQ/Services/CalendarService.swift" ]; then
    echo "  → CalendarService.swift"
    cp "$INTEGRATION_DIR/InboxIQ/Services/CalendarService.swift" "$TARGET_DIR/Services/" && chmod 666 "$TARGET_DIR/Services/CalendarService.swift"
fi

# Copy ViewModels
if [ -f "$INTEGRATION_DIR/InboxIQ/ViewModels/CalendarAuthViewModel.swift" ]; then
    echo "  → CalendarAuthViewModel.swift"
    cp "$INTEGRATION_DIR/InboxIQ/ViewModels/CalendarAuthViewModel.swift" "$TARGET_DIR/ViewModels/" && chmod 666 "$TARGET_DIR/ViewModels/CalendarAuthViewModel.swift"
fi

if [ -f "$INTEGRATION_DIR/InboxIQ/ViewModels/CalendarListViewModel.swift" ]; then
    echo "  → CalendarListViewModel.swift"
    cp "$INTEGRATION_DIR/InboxIQ/ViewModels/CalendarListViewModel.swift" "$TARGET_DIR/ViewModels/" && chmod 666 "$TARGET_DIR/ViewModels/CalendarListViewModel.swift"
fi

# Copy Views
if [ -d "$INTEGRATION_DIR/InboxIQ/Views/Calendar" ]; then
    echo "  → Calendar views"
    cp -r "$INTEGRATION_DIR/InboxIQ/Views/Calendar/"* "$TARGET_DIR/Views/Calendar/" 2>/dev/null || true
    chmod 666 "$TARGET_DIR/Views/Calendar/"*.swift 2>/dev/null || true
fi

# Copy Models
if [ -f "$INTEGRATION_DIR/InboxIQ/Models/CalendarEvent.swift" ]; then
    echo "  → CalendarEvent.swift"
    cp "$INTEGRATION_DIR/InboxIQ/Models/CalendarEvent.swift" "$TARGET_DIR/Models/" && chmod 666 "$TARGET_DIR/Models/CalendarEvent.swift"
fi

# Copy CoreData extensions
if [ -f "$INTEGRATION_DIR/InboxIQ/CoreData/CalendarEntity+Extensions.swift" ]; then
    echo "  → CalendarEntity+Extensions.swift"
    cp "$INTEGRATION_DIR/InboxIQ/CoreData/CalendarEntity+Extensions.swift" "$TARGET_DIR/CoreData/" && chmod 666 "$TARGET_DIR/CoreData/CalendarEntity+Extensions.swift"
fi

# Copy updated shared files
if [ -f "$INTEGRATION_DIR/InboxIQ/Views/ContentView.swift" ]; then
    echo "  → ContentView.swift (updated with Calendar tab)"
    cp "$INTEGRATION_DIR/InboxIQ/Views/ContentView.swift" "$TARGET_DIR/Views/" && chmod 666 "$TARGET_DIR/Views/ContentView.swift"
fi

if [ -f "$INTEGRATION_DIR/InboxIQ/InboxIQApp.swift" ]; then
    echo "  → InboxIQApp.swift (updated)"
    cp "$INTEGRATION_DIR/InboxIQ/InboxIQApp.swift" "$TARGET_DIR/" && chmod 666 "$TARGET_DIR/InboxIQApp.swift"
fi

if [ -f "$INTEGRATION_DIR/InboxIQ/Utils/Constants.swift" ]; then
    echo "  → Constants.swift (updated with calendar endpoints)"
    cp "$INTEGRATION_DIR/InboxIQ/Utils/Constants.swift" "$TARGET_DIR/Utils/" && chmod 666 "$TARGET_DIR/Utils/Constants.swift"
fi

if [ -f "$INTEGRATION_DIR/InboxIQ/CoreData/PersistenceController.swift" ]; then
    echo "  → PersistenceController.swift (updated)"
    cp "$INTEGRATION_DIR/InboxIQ/CoreData/PersistenceController.swift" "$TARGET_DIR/CoreData/" && chmod 666 "$TARGET_DIR/CoreData/PersistenceController.swift"
fi

if [ -f "$INTEGRATION_DIR/InboxIQ/Info.plist" ]; then
    echo "  → Info.plist (updated with calendar callback URL scheme)"
    cp "$INTEGRATION_DIR/InboxIQ/Info.plist" "$TARGET_DIR/" && chmod 666 "$TARGET_DIR/Info.plist"
fi

echo ""
echo "✅ All files copied successfully!"
echo ""

# Count files
SWIFT_FILES=$(find "$TARGET_DIR" -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
echo "📊 Integration Summary"
echo "====================="
echo "📈 Total Swift files in project: $SWIFT_FILES"
echo ""

echo "⚠️  NEXT STEPS - MANUAL XCODE CONFIGURATION:"
echo "============================================"
echo ""
echo "1. Open Xcode project:"
echo "   open \"$XCODE_PROJECT\""
echo ""
echo "2. Add new files to Xcode (Right-click InboxIQ folder → Add Files):"
echo "   • Services/CalendarService.swift"
echo "   • ViewModels/CalendarAuthViewModel.swift"
echo "   • ViewModels/CalendarListViewModel.swift"
echo "   • Views/Calendar/*.swift (4 files)"
echo "   • Models/CalendarEvent.swift"
echo "   • CoreData/CalendarEntity+Extensions.swift"
echo ""
echo "3. Update CoreData Model (InboxIQ.xcdatamodeld):"
echo "   • Add CalendarEventEntity (8 attributes)"
echo "   • Update UserEntity (add calendarConnected + calendarEvents)"
echo ""
echo "4. Update Constants.swift for production:"
echo "   static let apiBaseURL = \"https://inboxiq-production-5368.up.railway.app\""
echo ""
echo "5. Build & Test (⌘B then ⌘R)"
echo ""
echo "📝 Full guide: $INTEGRATION_DIR/README.md"
echo ""
echo "✅ Integration complete!"
