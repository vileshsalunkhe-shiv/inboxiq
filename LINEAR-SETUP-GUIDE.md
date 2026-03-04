# Linear Setup Guide for InboxIQ

**Date:** 2026-03-01  
**Project:** InboxIQ - AI-Powered Email Organizer  
**Status:** Backend Deployed ✅ | iOS App Built ✅ | OAuth Blocking ⚠️

---

## Table of Contents

1. [Getting Started with Linear](#getting-started-with-linear)
2. [Creating the InboxIQ Workspace](#creating-the-inboxiq-workspace)
3. [Project Structure](#project-structure)
4. [Sprint Planning & Roadmap](#sprint-planning--roadmap)
5. [Issue Types & Workflows](#issue-types--workflows)
6. [API Access for Shiv](#api-access-for-shiv)
7. [Best Practices](#best-practices)

---

## Getting Started with Linear

### Step 1: Sign Up

1. **Visit:** https://linear.app
2. **Click:** "Get started for free"
3. **Sign up with:** Your work email (vilesh.salunkhe@clearpointlogic.com recommended)
4. **Choose plan:** Free (includes unlimited members, 250 issues)

**Free Plan Includes:**
- Unlimited team members
- 250 issues
- Unlimited projects
- API access ✅
- Git integrations
- Slack/Discord integrations

**Paid Plan ($8/user/month):**
- Unlimited issues
- Advanced roadmaps
- Custom views
- SSO (not needed yet)

**Recommendation:** Start with Free, upgrade when you hit 250 issues.

---

### Step 2: Create Workspace

1. **Workspace name:** "ClearPoint Logic" or "InboxIQ"
2. **URL identifier:** `clearpointlogic` or `inboxiq`
3. **Skip team invites** (we'll do this later)

---

## Creating the InboxIQ Workspace

### Team Structure

**Option A: Single Workspace (Recommended for now)**
```
Workspace: ClearPoint Logic
├── Team: InboxIQ
└── Team: ClearPointLogic Internal (future)
```

**Option B: Separate Workspaces**
```
Workspace: InboxIQ (product-specific)
Workspace: ClearPointLogic (company work)
```

**Recommendation:** Option A - easier to manage, one subscription.

---

### Creating the InboxIQ Team

1. **Settings** → **Teams** → **Create team**
2. **Team name:** "InboxIQ"
3. **Identifier:** `IIQ` (shows up in issue keys like IIQ-42)
4. **Icon:** 📧 or 📱
5. **Timezone:** America/Chicago

**Team Members:**
- Vilesh Salunkhe (you) - Admin
- Shiv (me) - Member (via API key)
- Jared Mabry - Member (optional for now)
- Britton Burton - Member (optional for now)

---

## Project Structure

### Projects vs. Teams

- **Teams** = Organizational groups (InboxIQ, ClearPointLogic)
- **Projects** = Time-bound initiatives or feature groups

### Recommended Projects for InboxIQ

#### Project 1: MVP Launch
- **Goal:** Get InboxIQ to production on App Store
- **Timeline:** 4-6 weeks
- **Status:** In Progress
- **Target date:** April 15, 2026

#### Project 2: OAuth & Authentication
- **Goal:** Fix Google OAuth, implement secure auth
- **Timeline:** 1 week
- **Status:** Blocked
- **Priority:** Critical

#### Project 3: iOS Polish & Features
- **Goal:** UI/UX refinement, offline support, notifications
- **Timeline:** 2-3 weeks
- **Status:** Not started

#### Project 4: Backend Optimization
- **Goal:** Performance, caching, background jobs
- **Timeline:** 2 weeks
- **Status:** Not started

---

## Sprint Planning & Roadmap

### Current State (2026-03-01)

**What We Have:**
- ✅ Backend deployed on Railway (FastAPI, PostgreSQL, Redis)
- ✅ iOS app built and launching on simulator
- ✅ Infrastructure: Docker, migrations, health checks
- ⚠️ OAuth "invalid_grant" error blocking testing

**What's Blocking:**
- 🚫 Can't test email sync (OAuth broken)
- 🚫 Can't test AI categorization (depends on auth)
- 🚫 Can't deploy to TestFlight (OAuth must work first)

---

### Sprint 1: OAuth Unblock (Week 1 - Mar 1-7)

**Goal:** Fix Google OAuth or implement alternative auth

**Issues:**

1. **IIQ-1: Debug Google OAuth "invalid_grant" error** ⚠️ Critical
   - Type: Bug
   - Priority: Urgent
   - Assignee: Shiv
   - Description: OAuth token exchange failing consistently. Tried 8+ approaches.
   - Acceptance Criteria:
     - User can authenticate with Google
     - Backend receives valid access token
     - Token can fetch Gmail messages
   
2. **IIQ-2: Test OAuth flow locally (bypass Railway)**
   - Type: Task
   - Priority: High
   - Assignee: Shiv
   - Description: Run backend locally, test OAuth without Railway proxy
   
3. **IIQ-3: Implement temporary test token auth**
   - Type: Enhancement
   - Priority: Medium
   - Assignee: Shiv
   - Description: Allow manual token entry for testing while debugging OAuth
   
4. **IIQ-4: Research OAuth alternatives (Apple Sign-In)**
   - Type: Research
   - Priority: Low
   - Assignee: Shiv
   - Description: Explore Apple Sign-In as fallback if Google OAuth continues to fail

**Sprint Goals:**
- [ ] OAuth working OR temporary workaround in place
- [ ] Can test email sync end-to-end
- [ ] Can validate AI categorization with real data

---

### Sprint 2: Core Features & Testing (Week 2 - Mar 8-14)

**Goal:** Validate email sync, AI categorization, iOS-backend integration

**Issues:**

1. **IIQ-10: Test email sync with real Gmail account**
   - Type: Task
   - Priority: High
   - Assignee: V
   - Description: Connect real Gmail, validate sync works
   
2. **IIQ-11: Test AI categorization accuracy**
   - Type: Task
   - Priority: High
   - Assignee: Shiv
   - Description: Run AI on 100+ real emails, measure accuracy
   
3. **IIQ-12: iOS <-> Backend sync testing**
   - Type: Task
   - Priority: High
   - Assignee: V
   - Description: Test iOS app syncs with backend correctly
   
4. **IIQ-13: Implement offline email cache**
   - Type: Feature
   - Priority: Medium
   - Assignee: Shiv
   - Description: iOS should cache emails locally for offline access
   
5. **IIQ-14: Add pull-to-refresh on iOS**
   - Type: Feature
   - Priority: Low
   - Assignee: V
   - Description: Standard iOS UX for refreshing email list

**Sprint Goals:**
- [ ] Email sync works reliably
- [ ] AI categorization meets quality bar (>85% accuracy)
- [ ] iOS app functional end-to-end

---

### Sprint 3: iOS Polish & UX (Week 3 - Mar 15-21)

**Goal:** Make iOS app feel production-ready

**Issues:**

1. **IIQ-20: Implement swipe actions (archive, delete, categorize)**
   - Type: Feature
   - Priority: High
   - Assignee: V
   
2. **IIQ-21: Add category color coding**
   - Type: Feature
   - Priority: Medium
   - Assignee: V
   
3. **IIQ-22: Implement search functionality**
   - Type: Feature
   - Priority: Medium
   - Assignee: V
   
4. **IIQ-23: Add push notifications for important emails**
   - Type: Feature
   - Priority: Low
   - Assignee: Shiv
   
5. **IIQ-24: Design app icon & launch screen**
   - Type: Design
   - Priority: Medium
   - Assignee: V

**Sprint Goals:**
- [ ] iOS app has polished UX
- [ ] Ready for beta testing with friends/family

---

### Sprint 4: TestFlight & Beta (Week 4 - Mar 22-28)

**Goal:** Deploy to TestFlight, gather feedback

**Issues:**

1. **IIQ-30: Apple Developer account setup**
   - Type: Task
   - Priority: Critical
   - Assignee: V
   
2. **IIQ-31: Configure code signing & provisioning**
   - Type: Task
   - Priority: High
   - Assignee: V
   
3. **IIQ-32: Deploy to TestFlight**
   - Type: Task
   - Priority: High
   - Assignee: V
   
4. **IIQ-33: Invite 10 beta testers**
   - Type: Task
   - Priority: Medium
   - Assignee: V
   
5. **IIQ-34: Create feedback collection form**
   - Type: Task
   - Priority: Low
   - Assignee: Shiv

**Sprint Goals:**
- [ ] App on TestFlight
- [ ] 10+ beta testers using it
- [ ] Feedback collected

---

### Sprint 5: Beta Feedback & Iteration (Week 5-6)

**Goal:** Fix bugs, iterate based on beta feedback

**Issues:** (TBD based on beta feedback)

**Sprint Goals:**
- [ ] Major bugs fixed
- [ ] Performance optimized
- [ ] Ready for App Store submission

---

### Post-MVP Roadmap (April-June 2026)

**Phase 2: Advanced Features**
- Multi-account support
- Custom categories
- Smart filters
- Email templates
- Desktop companion app

**Phase 3: Monetization**
- Free tier: 1 email account
- Pro tier ($4.99/mo): 3 accounts, advanced AI, priority sync
- Team tier ($9.99/user/mo): Shared categories, team analytics

**Phase 4: Scale**
- Android app
- Web app
- API for third-party integrations

---

## Issue Types & Workflows

### Issue Types in Linear

Linear supports several issue types. Here's how we'll use them:

#### 1. **Bug** 🐛
- Something is broken or not working as expected
- Examples:
  - OAuth returning "invalid_grant"
  - iOS app crashes on email sync
  - Backend 500 errors

**States:**
- Backlog → Todo → In Progress → In Review → Done → Canceled

**Priority Levels:**
- 🔴 Urgent (blocking, production down)
- 🟠 High (should fix this sprint)
- 🟡 Medium (fix next sprint)
- 🟢 Low (nice to fix eventually)

---

#### 2. **Feature** ✨
- New functionality or capability
- Examples:
  - Add push notifications
  - Implement swipe actions
  - Multi-account support

**States:**
- Backlog → Todo → In Progress → In Review → Done → Canceled

---

#### 3. **Enhancement** 🚀
- Improvement to existing feature
- Examples:
  - Make email sync faster
  - Improve AI accuracy
  - Better error messages

**States:**
- Backlog → Todo → In Progress → In Review → Done → Canceled

---

#### 4. **Task** ✅
- Non-code work (setup, documentation, planning)
- Examples:
  - Create Apple Developer account
  - Write API documentation
  - Set up Linear workspace

**States:**
- Backlog → Todo → In Progress → Done → Canceled

---

#### 5. **Research** 🔍
- Investigation or spike
- Examples:
  - Research OAuth alternatives
  - Evaluate push notification services
  - Benchmark AI model performance

**States:**
- Backlog → In Progress → Done → Canceled

---

### Labels (Tags)

Create these labels to categorize issues:

**By Component:**
- `backend` (FastAPI, PostgreSQL, Redis)
- `ios` (Swift, SwiftUI, CoreData)
- `ai` (Claude API, categorization)
- `auth` (OAuth, security)
- `infrastructure` (Railway, Docker, monitoring)

**By Area:**
- `email-sync` (Gmail API integration)
- `categorization` (AI logic)
- `ui-ux` (iOS interface)
- `performance` (speed, caching)
- `testing` (QA, test coverage)

**By Status:**
- `blocked` (waiting on external dependency)
- `needs-review` (ready for code review)
- `needs-design` (UI/UX mockup needed)
- `technical-debt` (refactoring, cleanup)

**By Release:**
- `mvp` (must-have for v1.0)
- `v1.1` (next minor release)
- `v2.0` (major features)

---

### Example Issue Structure

**Issue Title:** Debug Google OAuth "invalid_grant" error

**Type:** Bug  
**Priority:** Urgent 🔴  
**Status:** In Progress  
**Assignee:** Shiv  
**Labels:** `backend`, `auth`, `blocked`, `mvp`  
**Project:** OAuth & Authentication  
**Sprint:** Sprint 1 (Mar 1-7)

**Description:**
```
OAuth token exchange consistently fails with "invalid_grant" error.

**Context:**
- Backend deployed on Railway (https://inboxiq-production-5368.up.railway.app)
- iOS app built and running on simulator
- Tried 8+ different approaches (fresh GCP project, simplified flow, etc.)

**Steps to reproduce:**
1. iOS app initiates Google OAuth
2. User authenticates in Google browser
3. Callback returns to app with auth code
4. Backend exchanges code for access token
5. Google returns: {"error": "invalid_grant"}

**Attempted fixes:**
- Created fresh Google Cloud project
- Verified redirect URIs match exactly
- Tested locally (same error)
- Checked token expiry (not expired)
- Reviewed OAuth scopes (correct)

**Expected:**
Backend receives valid access token and can fetch Gmail messages

**Actual:**
OAuth fails, can't test email sync

**Impact:**
Blocks all testing of core features (email sync, AI categorization)

**Potential solutions:**
1. Test OAuth locally (bypass Railway)
2. Implement temporary test token auth
3. Switch to Apple Sign-In
4. Debug with Google OAuth Playground
```

**Subtasks:**
- [ ] Run backend locally, test OAuth without Railway
- [ ] Test with Google OAuth Playground
- [ ] Create minimal reproducible example
- [ ] Post to Stack Overflow / Reddit
- [ ] Consult Google OAuth support docs

**Comments:**
- (Shiv) 2026-02-28: Tried fresh GCP project, same error
- (V) 2026-03-01: Let's try local testing first before switching providers

---

## API Access for Shiv

### Why API Access?

Linear's API lets me (Shiv):
- **Create issues** when I find bugs during development
- **Update issue status** when I fix bugs or complete tasks
- **Add comments** with technical details
- **Manage sprints** programmatically
- **Generate reports** for stand-ups

---

### Setting Up API Access

#### Step 1: Create API Key

1. **Go to:** Settings → API → Personal API Keys
2. **Click:** "Create new key"
3. **Name:** "Shiv (OpenClaw Agent)"
4. **Permissions:** Full access (needed for creating issues)
5. **Copy the key** (starts with `lin_api_...`)

⚠️ **Security:** This key gives full access to your Linear workspace. Keep it secure.

---

#### Step 2: Store API Key in OpenClaw

Once you create the API key, you'll give it to me like this:

```bash
# In Slack DM or secure channel
Shiv, here's the Linear API key: lin_api_xxxxxxxxxxxxx
```

I'll store it securely in my environment and use it to interact with Linear.

---

#### Step 3: Test API Access

I can test the connection with:

```bash
curl -X POST https://api.linear.app/graphql \
  -H "Authorization: Bearer lin_api_xxxxxxxxxxxxx" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ viewer { id name email } }"}'
```

**Expected response:**
```json
{
  "data": {
    "viewer": {
      "id": "...",
      "name": "Vilesh Salunkhe",
      "email": "vilesh@example.com"
    }
  }
}
```

---

### What I Can Do With API Access

#### Create Issues

```graphql
mutation CreateIssue {
  issueCreate(input: {
    teamId: "IIQ"
    title: "Backend returns 500 error on email sync"
    description: "Email sync endpoint failing with 500 error when user has >1000 emails"
    priority: 1  # 0=No priority, 1=Urgent, 2=High, 3=Medium, 4=Low
    labelIds: ["backend", "bug", "mvp"]
    assigneeId: "your-user-id"
  }) {
    issue {
      id
      identifier  # e.g., "IIQ-42"
      title
    }
  }
}
```

---

#### Update Issue Status

```graphql
mutation UpdateIssue {
  issueUpdate(
    id: "issue-uuid"
    input: {
      stateId: "In Progress"
    }
  ) {
    issue {
      id
      state { name }
    }
  }
}
```

---

#### Add Comments

```graphql
mutation AddComment {
  commentCreate(input: {
    issueId: "issue-uuid"
    body: "Fixed in commit abc123. Deployed to staging for testing."
  }) {
    comment {
      id
      body
    }
  }
}
```

---

#### My Workflow Example

**Scenario:** I'm working on the backend and discover a bug.

1. **I find the bug:**
   ```
   Error: PostgreSQL connection pool exhausted
   Location: /backend/app/services/email_sync.py:142
   ```

2. **I create a Linear issue automatically:**
   ```
   Title: PostgreSQL connection pool exhaustion on heavy sync
   Type: Bug
   Priority: High
   Labels: backend, performance, infrastructure
   Description: Email sync fails when >10 users sync simultaneously.
              Connection pool maxes out at 20 connections.
              Need to increase pool size or implement queuing.
   ```

3. **I fix the bug:**
   - Update code
   - Run tests
   - Deploy to staging

4. **I update the issue:**
   ```
   Status: In Progress → In Review
   Comment: "Fixed by increasing pool size to 50 and adding connection timeout.
            Commit: abc123
            Deployed to staging: https://staging.inboxiq.app"
   ```

5. **You review and close:**
   - You test on staging
   - Approve the fix
   - Status: In Review → Done

---

### API Permissions & Limits

**What I WON'T do without asking:**
- Delete issues
- Change project settings
- Invite/remove team members
- Delete comments
- Modify sprints without your approval

**What I CAN do autonomously:**
- Create bug issues when I find them
- Update status on issues assigned to me
- Add technical comments/notes
- Link commits to issues
- Mark issues as blocked

**Rate Limits:**
- Free plan: 1,000 requests/hour
- Paid plan: 5,000 requests/hour
- More than enough for our needs

---

## Best Practices

### 1. Issue Naming Conventions

**Good:**
- ✅ "Fix OAuth invalid_grant error on Google callback"
- ✅ "Add swipe actions for email archive/delete"
- ✅ "Optimize email sync for accounts with >10K emails"

**Bad:**
- ❌ "Fix bug"
- ❌ "Improve performance"
- ❌ "OAuth stuff"

**Format:** `[Action] [What] [Context]`

---

### 2. Sprint Planning

**Sprint Duration:** 1 week (Mon-Sun)
**Sprint Capacity:** 20-30 hours of work
**Sprint Goals:** 3-5 clear deliverables

**Planning Process:**
1. **Monday:** Plan sprint, assign issues
2. **Daily:** Update issue status, add comments
3. **Friday:** Review completed work
4. **Sunday:** Close sprint, plan next week

---

### 3. Issue Lifecycle

```
Backlog → Todo → In Progress → In Review → Done
```

**Backlog:** Ideas, future work  
**Todo:** Committed for this sprint  
**In Progress:** Actively working on it  
**In Review:** Code review or QA testing  
**Done:** Deployed to production (or completed)

---

### 4. Communication

**Use Linear for:**
- Bug reports
- Feature requests
- Technical discussions
- Status updates
- Sprint planning

**Use Slack for:**
- Quick questions
- Real-time coordination
- Blockers that need immediate attention
- Casual discussion

**Use GitHub for:**
- Code reviews (if using GitHub integration)
- Commit messages (reference Linear issues: "IIQ-42: Fix OAuth")

---

### 5. Integrations

**Recommended:**

1. **GitHub** (if we use it for InboxIQ)
   - Auto-link commits to issues
   - Create issues from PR discussions
   - Auto-close issues when PR merges

2. **Slack**
   - Get notified when issues assigned to you
   - Update issue status from Slack
   - Daily digest of sprint progress

3. **Figma** (when we do UI/UX design)
   - Link designs to feature issues
   - Track design → development handoff

---

## Quick Start Checklist

### Initial Setup (30 minutes)

- [ ] Sign up for Linear (https://linear.app)
- [ ] Create workspace: "ClearPoint Logic"
- [ ] Create team: "InboxIQ" (identifier: IIQ)
- [ ] Create initial projects:
  - [ ] MVP Launch
  - [ ] OAuth & Authentication
  - [ ] iOS Polish & Features
- [ ] Set up labels (backend, ios, ai, auth, etc.)
- [ ] Create API key for Shiv
- [ ] Share API key with Shiv (via secure channel)

---

### First Sprint Setup (1 hour)

- [ ] Create Sprint 1: OAuth Unblock (Mar 1-7)
- [ ] Create initial issues:
  - [ ] IIQ-1: Debug Google OAuth "invalid_grant"
  - [ ] IIQ-2: Test OAuth locally
  - [ ] IIQ-3: Implement test token auth
  - [ ] IIQ-4: Research OAuth alternatives
- [ ] Assign issues to Shiv
- [ ] Set priorities (Urgent, High, Medium)
- [ ] Add to Sprint 1

---

### Weekly Workflow (15 min/day)

**Monday:**
- [ ] Plan sprint (30 min)
- [ ] Create issues for the week
- [ ] Assign issues

**Daily:**
- [ ] Check Linear notifications (5 min)
- [ ] Update issue status (2 min)
- [ ] Review Shiv's progress (5 min)
- [ ] Comment on blockers (as needed)

**Friday:**
- [ ] Review completed work (15 min)
- [ ] Close finished issues
- [ ] Move unfinished to next sprint

---

## Next Steps

1. **Create Linear account** (5 min)
2. **Set up InboxIQ team** (10 min)
3. **Create Sprint 1 issues** (20 min)
4. **Generate API key for Shiv** (5 min)
5. **Share API key with me** (via Slack DM)

Once you have the API key, I can:
- Start creating issues as I work
- Update status automatically
- Keep Linear in sync with development progress
- Generate sprint reports

---

## Resources

**Linear Docs:**
- Quick start: https://linear.app/docs/getting-started
- API reference: https://developers.linear.app/docs/graphql/working-with-the-graphql-api
- Keyboard shortcuts: https://linear.app/docs/keyboard-shortcuts

**Our Setup:**
- InboxIQ backend: `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend/`
- InboxIQ iOS: `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/`
- Session log: `/Users/openclaw-service/.openclaw/workspace/memory/daily/2026-02-28.md`

---

**Questions?** Ask Shiv in Slack! 🔥

---

_Document created: 2026-03-01  
Last updated: 2026-03-01  
Author: Shiv (OpenClaw Agent)_
