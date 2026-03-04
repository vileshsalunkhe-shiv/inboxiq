#!/bin/bash
set -e

# InboxIQ - Automated Calendar Integration Script
# Integrates Google Calendar features into existing iOS app
# Note: This script uses sudo for file operations

echo "🚀 InboxIQ Calendar Integration Script"
echo "======================================="
echo ""
echo "⚠️  This script requires sudo access for file operations."
echo "    You may be prompted for your password."
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

# Backup existing files
echo "📦 Creating backup..."
BACKUP_DIR="$TARGET_DIR/../InboxIQ-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
sudo cp -r "$TARGET_DIR" "$BACKUP_DIR/"
echo "✅ Backup created: $BACKUP_DIR"
echo ""

# Copy new files
echo "📋 Copying calendar integration files..."

# Create directory structure if missing
mkdir -p "$TARGET_DIR/Services"
mkdir -p "$TARGET_DIR/ViewModels"
mkdir -p "$TARGET_DIR/Views/Calendar"
mkdir -p "$TARGET_DIR/Models"
mkdir -p "$TARGET_DIR/CoreData"
mkdir -p "$TARGET_DIR/Utils"

# Copy Services
echo "  → CalendarService.swift"
sudo cp "$INTEGRATION_DIR/InboxIQ/Services/CalendarService.swift" "$TARGET_DIR/Services/"

# Copy ViewModels
echo "  → CalendarAuthViewModel.swift"
sudo cp "$INTEGRATION_DIR/InboxIQ/ViewModels/CalendarAuthViewModel.swift" "$TARGET_DIR/ViewModels/"
echo "  → CalendarListViewModel.swift"
sudo cp "$INTEGRATION_DIR/InboxIQ/ViewModels/CalendarListViewModel.swift" "$TARGET_DIR/ViewModels/"

# Copy Views
echo "  → Calendar views (4 files)"
sudo cp -r "$INTEGRATION_DIR/InboxIQ/Views/Calendar/"* "$TARGET_DIR/Views/Calendar/" 2>/dev/null || true

# Copy Models
echo "  → CalendarEvent.swift"
sudo cp "$INTEGRATION_DIR/InboxIQ/Models/CalendarEvent.swift" "$TARGET_DIR/Models/"

# Copy CoreData extensions
echo "  → CalendarEntity+Extensions.swift"
sudo cp "$INTEGRATION_DIR/InboxIQ/CoreData/CalendarEntity+Extensions.swift" "$TARGET_DIR/CoreData/"

# Copy updated shared files
echo "  → ContentView.swift (updated with Calendar tab)"
sudo cp "$INTEGRATION_DIR/InboxIQ/Views/ContentView.swift" "$TARGET_DIR/Views/"

echo "  → InboxIQApp.swift (updated)"
sudo cp "$INTEGRATION_DIR/InboxIQ/InboxIQApp.swift" "$TARGET_DIR/"

echo "  → Constants.swift (updated with calendar endpoints)"
sudo cp "$INTEGRATION_DIR/InboxIQ/Utils/Constants.swift" "$TARGET_DIR/Utils/"

echo "  → PersistenceController.swift (updated)"
sudo cp "$INTEGRATION_DIR/InboxIQ/CoreData/PersistenceController.swift" "$TARGET_DIR/CoreData/"

echo "  → Info.plist (updated with calendar callback URL scheme)"
sudo cp "$INTEGRATION_DIR/InboxIQ/Info.plist" "$TARGET_DIR/"

echo ""
echo "✅ All files copied successfully!"
echo ""

# Set proper permissions
echo "🔐 Setting file permissions..."
sudo find "$TARGET_DIR" -type f -name "*.swift" -exec chmod 666 {} \;
sudo chmod 666 "$TARGET_DIR/Info.plist"
sudo chown -R vileshsalunkhe_mc:staff "$TARGET_DIR"
echo "✅ Permissions set"
echo ""

# Summary
echo "📊 Integration Summary"
echo "====================="
echo "Files added/updated:"
echo "  - Services: CalendarService.swift"
echo "  - ViewModels: CalendarAuthViewModel, CalendarListViewModel"
echo "  - Views: CalendarConnectionView, CalendarListView, CalendarEventDetailView, CreateEventView"
echo "  - Models: CalendarEvent.swift"
echo "  - CoreData: CalendarEntity+Extensions.swift"
echo "  - Updated: ContentView, InboxIQApp, Constants, PersistenceController, Info.plist"
echo ""

# Count files
SWIFT_FILES=$(find "$TARGET_DIR" -name "*.swift" | wc -l | tr -d ' ')
echo "📈 Total Swift files in project: $SWIFT_FILES"
echo ""

echo "⚠️  NEXT STEPS - MANUAL XCODE CONFIGURATION:"
echo "============================================"
echo ""
echo "1. Open Xcode project:"
echo "   open \"$XCODE_PROJECT\""
echo ""
echo "2. Add new files to Xcode project:"
echo "   - Right-click 'InboxIQ' folder → 'Add Files to InboxIQ...'"
echo "   - Select:"
echo "     • Services/CalendarService.swift"
echo "     • ViewModels/CalendarAuthViewModel.swift"
echo "     • ViewModels/CalendarListViewModel.swift"
echo "     • Views/Calendar/*.swift (4 files)"
echo "     • Models/CalendarEvent.swift"
echo "     • CoreData/CalendarEntity+Extensions.swift"
echo "   - ✅ Check 'Copy items if needed'"
echo "   - Click 'Add'"
echo ""
echo "3. Update CoreData Model (InboxIQ.xcdatamodeld):"
echo ""
echo "   A. Add NEW entity: CalendarEventEntity"
echo "      Attributes:"
echo "        • id (UUID, required)"
echo "        • eventId (String, required)"
echo "        • summary (String, required)"
echo "        • eventDescription (String, optional)"
echo "        • startDate (Date, required)"
echo "        • endDate (Date, required)"
echo "        • location (String, optional)"
echo "        • htmlLink (String, optional)"
echo "      Relationships:"
echo "        • user → UserEntity (to-one, inverse: calendarEvents, delete: Nullify)"
echo ""
echo "   B. Update EXISTING entity: UserEntity"
echo "      Add attributes:"
echo "        • calendarConnected (Boolean, default: false)"
echo "      Add relationships:"
echo "        • calendarEvents → CalendarEventEntity (to-many, inverse: user, delete: Cascade)"
echo ""
echo "4. Update Constants.swift backend URL for production:"
echo "   static let apiBaseURL = \"https://inboxiq-production-5368.up.railway.app\""
echo ""
echo "5. Build and test:"
echo "   - Product → Build (⌘B)"
echo "   - Fix any compilation errors"
echo "   - Run on simulator/device (⌘R)"
echo "   - Test Calendar tab → OAuth flow"
echo ""
echo "📝 Detailed instructions: $INTEGRATION_DIR/CALENDAR-IOS-INTEGRATION.md"
echo ""
echo "✅ Files ready! Open Xcode and follow steps above."
echo ""
