#!/bin/bash
# Deploy Email Schema Fix to Railway

echo "🚀 Deploying Email Schema Fix"
echo ""

cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq

# 1. Show what changed
echo "1️⃣ Changes made:"
echo "   - app/schemas/email.py: Updated EmailOut schema"
echo "   - app/api/emails.py: Fixed 3 EmailOut serialization points"
echo "   - app/api/categorization.py: Fixed 1 EmailOut serialization point"
echo ""

# 2. Commit changes
echo "2️⃣ Committing changes..."
git add backend/app/schemas/email.py
git add backend/app/api/emails.py
git add backend/app/api/categorization.py
git commit -m "Fix: Email response schema to match iOS expectations

- Rename snippet → body_preview
- Rename received_at → received_date
- Add is_unread field
- Add is_starred field (default False)

Fixes iOS decoding error: 'The data couldn't be read because it is missing.'"

# 3. Push to GitHub
echo ""
echo "3️⃣ Pushing to GitHub..."
git push origin main

# 4. Deploy to Railway
echo ""
echo "4️⃣ Deploying to Railway..."
railway up

echo ""
echo "✅ Deployment complete!"
echo ""
echo "5️⃣ Test in iOS app:"
echo "   - Kill app"
echo "   - Rebuild (⌘B)"
echo "   - Run (⌘R)"
echo "   - Login"
echo "   - Emails should now display!"
