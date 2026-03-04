#!/bin/bash
# Fix iOS project permissions for Xcode import

echo "🔧 Fixing iOS project permissions..."
echo ""

TARGET_DIR="/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ"

# Change ownership to current user
echo "📝 Changing ownership to vileshsalunkhe_mc..."
sudo chown -R vileshsalunkhe_mc:staff "$TARGET_DIR"

# Set directory permissions (rwxrwxr-x)
echo "📂 Setting directory permissions..."
sudo find "$TARGET_DIR" -type d -exec chmod 775 {} \;

# Set file permissions (rw-rw-r--)
echo "📄 Setting file permissions..."
sudo find "$TARGET_DIR" -type f -exec chmod 664 {} \;

# Make sure .xcodeproj is accessible
echo "🔨 Ensuring Xcode project is accessible..."
sudo chmod -R 775 "$TARGET_DIR/InboxIQ.xcodeproj"

echo ""
echo "✅ Permissions fixed!"
echo ""
echo "You can now:"
echo "1. Open Xcode: open $TARGET_DIR/InboxIQ.xcodeproj"
echo "2. Import the new calendar files"
echo ""
