# Autonomous Testing - Simple Instructions

## Problem with First Setup
Homebrew permissions issue. **We'll skip Railway for now** (not critical - I can get logs other ways).

Focus: **iOS testing** (the real time-saver).

---

## Simple 2-Step Process

### Step 1: Run This Once (Test It Works)

```bash
bash /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/SIMPLE-TEST.sh
```

**What happens:**
- Script starts capturing iOS logs
- You'll see: "NOW: Go to Xcode and run the app"

**Then you:**
1. Switch to Xcode
2. Build & run (Cmd+R)
3. Test the app (login, sync, check inbox)
4. Come back to Terminal
5. Press Ctrl+C

**Result:** Logs saved to timestamped file in `/projects/inboxiq/test-logs-*.log`

---

### Step 2: I Read Logs & Batch Fixes

After you press Ctrl+C:
1. I read the log file directly (no need to paste)
2. I identify ALL issues at once
3. I apply comprehensive fixes
4. I tell you: "Fixed 5 issues, run SIMPLE-TEST.sh again"

You run the test script again → I read new logs → Either ✅ done or 🔄 one more round.

---

## Example Session

**You:**
```bash
bash SIMPLE-TEST.sh
# [switch to Xcode, test for 1-2 minutes, Ctrl+C]
```

**Me:**
- Reads log file
- "Found 3 issues: (1) HTML in email body, (2) wrong sorting, (3) date parsing error"
- Applies fixes to all 3
- "Fixed! Run SIMPLE-TEST.sh again to verify"

**You:**
```bash
bash SIMPLE-TEST.sh
# [switch to Xcode, test again, Ctrl+C]
```

**Me:**
- Reads log file
- "All issues resolved! ✅"

**Total time:** ~5 minutes vs ~2 hours

---

## What You Need to Do Right Now

Run this **once** to test it works:

```bash
bash /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/SIMPLE-TEST.sh
```

Then follow the prompts. When you press Ctrl+C, tell me the test completed and I'll read the logs.

---

## Railway Setup (Later, Optional)

If we need Railway log access later, you can run:
```bash
sudo chown -R openclaw-service /opt/homebrew
brew install railway
railway login
```

But **not needed for iOS testing**.

---

## Why This Works

**Before (today):**
- V: Tests in Xcode
- V: Copies entire console log, pastes in Slack
- Shiv: Reads, finds 1 issue
- Shiv: "Try this fix"
- Repeat 15 times ❌

**After (with script):**
- V: Runs script, tests in Xcode, presses Ctrl+C
- Shiv: Reads log file directly, finds ALL issues
- Shiv: Applies batch of fixes
- V: Runs script again
- Repeat 2-3 times ✅

---

Ready to try? Run the SIMPLE-TEST.sh script now!
