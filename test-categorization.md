# Test AI Categorization - Quick Guide

## Option 1: Test via iOS App (Easiest)

### Step 1: Open iOS App
1. Launch InboxIQ in simulator (already logged in)
2. Go to Settings or About section

### Step 2: Get Your Access Token
The iOS app stores your JWT token in Keychain. We need to extract it to test the API.

**Easy way:** Add a temporary button in Settings that copies token to clipboard.

**Quick way:** Test via curl with manual login.

---

## Option 2: Test via Curl (Quick Verification)

Since you're already logged in, we can trigger categorization and see results:

### 1. Login via API to get token:
```bash
# Get auth code from iOS OAuth (you did this already)
# For now, let's do a fresh login via curl:

# This is complex - let's just trigger categorization from backend directly
```

---

## Option 3: Trigger Categorization Directly (Simplest!)

Since we have your user in the database, we can trigger categorization for all your emails:

```bash
# Get your user_id from Railway logs (you saw it earlier: 1ae0ee58-a04f-47b2-ba79-5779bff48b65)

# Categorize all emails (this works without auth for testing)
curl -X POST "https://inboxiq-production-5368.up.railway.app/emails/categorize-all?limit=50" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## What I Recommend:

**Let's build the iOS UI first, then test end-to-end!**

That way you can:
1. See the category badges on emails
2. Trigger categorization with a button
3. Test the full user experience
4. Verify everything works together

**This is faster and more fun than curl commands!** 🎨

Ready to spawn DEV-MOBILE-premium for iOS UI?

---

**Alternative:** I can manually trigger categorization via a backend script if you want to verify AI works first.
