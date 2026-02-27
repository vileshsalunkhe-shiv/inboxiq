# InboxIQ - Lean Launch Strategy
**Alternate Approach: Start Small, Grow Smart**

---

## 🎯 Core Philosophy

**Problem:** Building the full InboxIQ vision (130+ features, 5-phase plan) requires significant upfront investment with unvalidated market demand.

**Solution:** Phased investment strategy that validates demand at each stage before scaling.

**Principle:** "Crawl → Walk → Run" - Prove it works before you scale it.

---

## 📊 Phased Investment Strategy

### Phase 0: Validation ($0-500, 2-4 weeks)
**Goal:** Prove people want this before building anything

**Activities:**
1. **Landing page + waitlist** (Carrd.co - $19/year)
   - Simple one-page site explaining InboxIQ
   - Email signup for early access
   - Target: 100+ signups = validation signal

2. **User interviews** (free, time investment only)
   - Interview 10-15 people about email pain points
   - Validate our feature assumptions
   - Refine MVP scope based on real feedback
   - Questions:
     - "What frustrates you most about email?"
     - "What would make you switch email apps?"
     - "Would you pay $X/month for [feature]?"

3. **Competitor user research** (free)
   - Read App Store reviews (Superhuman, Hey, Spark, Gmail)
   - Identify gaps in existing products
   - Find underserved user segments
   - Document feature requests competitors ignore

**Investment:** $20-100
- Domain name: $15/year
- Carrd.co: $19/year (or free tier)
- Email service: $0 (ConvertKit free tier for <1,000 subscribers)

**Success Criteria:**
- ✅ 100+ waitlist signups
- ✅ 10+ user interviews completed
- ✅ Clear problem/solution validation
- ✅ Defined MVP feature set (based on real user pain)

**Go/No-Go Decision:** If we can't get 100 signups with a compelling landing page, the market may not want this. Pivot or stop.

**Deliverables:**
- Landing page live
- Waitlist of 100+ interested users
- User interview notes and insights
- Refined MVP feature list
- Validated pricing hypothesis

---

### Phase 1: MVP Launch ($1,000-2,000, 8-12 weeks)
**Goal:** Ship working product to App Store, acquire first paying users

**Two Approaches:**

#### Option A: No-Code Prototype (Fastest, Lowest Risk)
**Use if:** Need to validate faster, limited development resources

**Stack:**
- **n8n** - Email processing workflows (self-hosted or cloud)
- **Glide/FlutterFlow/Adalo** - No-code mobile app builder
- **Supabase** - Backend database (free tier: 500MB, 2 projects)
- **Claude API** - AI categorization (pay-as-you-go)
- **Apple Developer Account** - $99/year

**Pros:**
- Ship in 2-4 weeks (vs 8+ weeks custom)
- Lower technical complexity
- Easy to iterate
- Minimal code = less to maintain

**Cons:**
- Limited customization
- Platform lock-in
- May hit scaling limits faster
- Less "native" feel

**Cost Breakdown:**
- Apple Developer: $99/year
- Domain: $15/year
- n8n Cloud: $20/month (or self-host for free)
- Supabase: $0 (free tier, upgrade at $25/month later)
- Claude API: $50-100/month (development + early users)

**Total:** $200-400 for first 3 months

---

#### Option B: Custom Build (Our Current Plan - More Scalable)
**Use if:** Want full control, plan to scale, have dev resources (our agent architecture)

**Stack:**
- **iOS:** Swift/SwiftUI (native iPhone app)
- **Backend:** FastAPI (Python)
- **Database:** PostgreSQL
- **Hosting:** Railway.app (free tier → $5-20/month)
- **AI:** Claude API (pay-as-you-go)
- **Storage:** Railway/S3 (minimal for MVP)

**Pros:**
- Full control and customization
- Native iOS performance
- Easier to scale long-term
- Better user experience
- We already have agent architecture set up

**Cons:**
- Longer development time (8+ weeks)
- More technical complexity
- Higher upfront time investment

**Cost Breakdown:**
- Apple Developer: $99/year
- Domain: $15/year
- Railway.app: $0-20/month (free tier, then Hobby $5 or Pro $20)
- PostgreSQL: $0 (included in Railway)
- Claude API: $100-200/month (development + testing + early users)
- Development: $0 (using our agent architecture - already available)

**Total:** $500-1,000 for first 3 months

---

### MVP Feature Set (Absolute Minimum)

**Week 1-8 Focus: Ship This and ONLY This**

1. **Authentication**
   - Gmail OAuth 2.0 login only
   - Single account support
   - Secure token storage (iOS Keychain)

2. **Email Sync**
   - Fetch emails via Gmail API
   - Background sync (every 15-30 minutes)
   - Push notifications for new email
   - Mark as read/unread

3. **AI Categorization**
   - Claude AI categorizes emails into:
     - Primary (important, from people)
     - Social (social networks)
     - Promotions (marketing, sales)
     - Updates (confirmations, receipts)
   - Visual inbox organization by category

4. **Basic Inbox Management**
   - List view (inbox, sent, archive)
   - Read email (text + attachments preview)
   - Archive email
   - Delete email
   - Search (basic text search)

5. **Compose & Reply**
   - Compose new email
   - Reply to email
   - Forward email
   - Basic text formatting
   - Attach files from Photos/Files

6. **Notifications**
   - Push notifications for new emails
   - Badge count on app icon
   - Notification preferences (on/off per category)

**What's NOT in MVP (Phase 2+):**
- ❌ Multiple accounts
- ❌ Snooze
- ❌ Send later
- ❌ Templates
- ❌ Smart compose/reply
- ❌ Calendar integration
- ❌ Team features
- ❌ iPad app
- ❌ Any advanced AI features

**Why This Scope?**
- Proves core value: "AI makes email better"
- Shippable in 8 weeks with our agents
- Low infrastructure costs (<$50/month)
- Can charge for it ($4.99/month)
- Easy to add features based on user feedback

---

### Monetization Strategy (MVP Phase)

**Pricing Model:**
- **7-day free trial** (no credit card required)
- **$4.99/month** subscription (lower than final $9.99 price)
  - Why lower? Easier early adoption, gather feedback, increase price in Phase 2
- **Single tier** (no Free/Pro split yet - simplify)

**Revenue Targets:**
- **Month 1:** 10 paying users = $50/month MRR
- **Month 2:** 25 paying users = $125/month MRR
- **Month 3:** 50 paying users = $250/month MRR

**Break-Even Analysis:**
- Monthly costs: $50-150 (infrastructure + AI)
- Break-even: 10-30 paying users
- At 5% free→paid conversion: 200-600 total users needed

**Investment:** $1,000-2,000 over 3 months
**Break-even:** Month 2-3 if hitting targets

---

### Go/No-Go Criteria (End of Phase 1)

**Proceed to Phase 2 if:**
- ✅ 50+ paying users
- ✅ App Store rating 4.5+
- ✅ <10% monthly churn
- ✅ 20%+ weekly active usage
- ✅ Positive user feedback on core features
- ✅ Clear feature requests pointing to Phase 2 priorities

**Pivot or Stop if:**
- ❌ <20 paying users after 3 months
- ❌ High churn (>20%/month)
- ❌ App Store rating <4.0
- ❌ Users complaining about core functionality (not feature requests)

---

## Phase 2: Growth ($3,000-5,000, 3-6 months)
**Goal:** Product-market fit proven, scale to 1,000+ users

**Trigger to Start Phase 2:**
- 50+ paying users from Phase 1
- Positive reviews and low churn
- Clear demand for additional features
- Revenue covering costs

### What Changes:

#### 1. Expand Features (Based on User Feedback)
**Most Requested Features First:**
- Multiple email accounts (Gmail + Outlook + iCloud)
- Snooze emails (hide until later)
- Send later (schedule emails)
- Email templates / canned responses
- Swipe gestures (archive, delete, snooze)

**Development:** 4-6 weeks for all above

#### 2. Scale Infrastructure
- **Upgrade Railway** ($20-50/month for Pro plan)
- **Add Redis** for caching (reduce API calls, improve speed)
- **CDN for attachments** (CloudFlare R2 or S3)
- **Monitoring** (Sentry for error tracking - $26/month)

**Cost:** +$50-100/month

#### 3. Marketing Budget
- **Apple Search Ads** ($500-1,000/month)
  - Target keywords: "email app", "gmail app", "AI email"
  - Goal: 5-10% install-to-paid conversion
- **Content marketing** (blog, SEO)
  - "Best email apps for [use case]"
  - "How AI improves email productivity"
- **Product Hunt launch** (free, high visibility)

**Cost:** $500-1,000/month

#### 4. Customer Support
- **Intercom or Crisp** ($79-99/month)
  - In-app chat support
  - Help center / knowledge base
  - Automated responses for common questions

**Cost:** $80-100/month

#### 5. Analytics & Insights
- **Mixpanel or Amplitude** (free tier < 100K events/month)
  - User behavior tracking
  - Feature adoption rates
  - Churn prediction
  - Funnel analysis

**Cost:** $0 initially, $50+/month when scaling

### Revenue Targets (Phase 2):
- **Month 4-6:** 100-200 paying users = $500-1,000 MRR
- **Month 7-9:** 300-600 paying users = $1,500-3,000 MRR

**Total Investment Phase 2:** $3,000-5,000 over 6 months
**Expected ROI:** Revenue should cover costs by Month 7-8

---

## Phase 3: Scale ($10,000-25,000, 6-12 months)
**Goal:** 10,000+ total users, $10K+ MRR, expand platform

**Trigger to Start Phase 3:**
- $3,000+ MRR from Phase 2
- Proven unit economics (LTV > 3x CAC)
- Strong demand for team features or additional platforms
- Cash flow positive

### What Changes:

#### 1. Platform Expansion
- **iPad app** (reuse 80% of iOS code, 2-3 weeks dev)
- **Mac app** (Catalyst or native SwiftUI, 4-6 weeks)
- **Web app** (for access anywhere, 6-8 weeks)

#### 2. Team Features
- Shared inbox (multiple users, one email account)
- Email assignment (assign to team member)
- Internal notes (comment without sending)
- Team analytics

**Market:** Small businesses, support teams
**Pricing:** $25/user/month (Team tier)

#### 3. Advanced Integrations
- **Calendar sync** (Google Calendar, Outlook)
- **Task management** (Todoist, Asana)
- **CRM integration** (HubSpot, Salesforce - for sales teams)

#### 4. Dedicated Infrastructure
- **Move to AWS/GCP** (more control, better scaling)
- **Separate staging/production** environments
- **Load balancing** for high availability
- **Database replication** for redundancy

**Cost:** $500-1,500/month infrastructure

#### 5. Team Expansion
- **Part-time support person** ($1,500-2,500/month contractor)
- **Part-time marketer** (content, SEO, paid ads)
- **Consider full-time engineer** (if demand warrants)

#### 6. Serious Marketing
- **Apple Search Ads:** $2,000-5,000/month
- **Content marketing:** Dedicated writer/SEO
- **Partnerships:** Productivity influencers, YouTubers
- **Referral program:** "Invite 3 friends, get 1 month free"

### Revenue Targets (Phase 3):
- **Month 10-12:** $10,000-20,000 MRR
  - 1,000-2,000 individual users at $9.99/month
  - 50-100 team users at $25/user/month

**Total Investment Phase 3:** $10,000-25,000 over 12 months
**Expected Outcome:** Profitable business with clear growth trajectory

---

## 💡 Ultra-Lean Launch Plan (Recommended for ClearPointLogic)

### Timeline & Investment:

#### Month 1-2: Validate ($100)
**Activities:**
1. Build landing page (Carrd.co)
2. Write compelling copy
3. Run 10-15 user interviews
4. Share on Reddit, Hacker News, Twitter, LinkedIn
5. Target: 100+ waitlist signups

**Investment:** $50-100 (domain + landing page tool)

**Go/No-Go:** If <50 signups, reassess messaging or problem fit

---

#### Month 3-4: Build MVP ($1,000)
**Activities:**
1. Development (using our agent architecture)
   - Core features only (see MVP scope above)
   - Use free tier infrastructure (Railway, Supabase)
   - Claude API for AI categorization
2. TestFlight beta with waitlist users
   - Invite 50-100 beta testers
   - Gather feedback
   - Fix critical bugs

**Investment:**
- Apple Developer: $99
- Infrastructure: $0-50 (free tiers)
- AI API: $100-200 (development + beta testing)
- Domain/tools: $50
- **Total: $250-400**

**Go/No-Go:** If beta users don't actively use it (20%+ weekly active), pivot or fix

---

#### Month 5-6: Launch & Iterate ($500)
**Activities:**
1. App Store submission (2-3 weeks review process)
2. Launch announcement to waitlist (100+ ready users)
3. Pricing: $4.99/month with 7-day free trial
4. Monitor metrics: installs, trial starts, conversions, churn
5. Rapid iteration based on user feedback

**Investment:**
- Infrastructure: $50-100/month
- AI API: $100-200/month
- Support tools: $0 (use email initially)
- **Total: $150-300/month**

**Success Metrics:**
- 10+ paying users in first month
- 4.5+ App Store rating
- <15% churn
- Clear feature requests (shows engagement)

---

#### Month 7-12: Grow ($2,000-3,000)
**Activities:**
1. Add Phase 2 features based on feedback
   - Multi-account support (most requested)
   - Snooze (second most requested)
   - Send later
2. Marketing push
   - Product Hunt launch (free)
   - Apple Search Ads ($300-500/month)
   - Content marketing (blog posts)
3. Scale infrastructure as needed
4. Target: 100 paying users ($500/month MRR)

**Investment:**
- Infrastructure: $100-200/month
- AI API: $200-400/month
- Marketing: $300-500/month
- **Total: $600-1,100/month**

**Success Target:** 
- 100 paying users by Month 12 = $500 MRR
- 4.5+ App Store rating
- Growing waitlist for new features

---

### Total Investment Year 1: $3,500-4,500

**Breakdown:**
- Months 1-2 (Validation): $100
- Months 3-4 (Build): $1,000
- Months 5-6 (Launch): $500
- Months 7-12 (Grow): $3,000-3,500
- **Total: $4,600**

### Revenue Target Year 1: $3,000-6,000

**Breakdown:**
- Months 1-4: $0 (pre-revenue)
- Month 5: $50 (10 users)
- Month 6: $125 (25 users)
- Month 7-8: $250/month (50 users)
- Month 9-10: $400/month (80 users)
- Month 11-12: $500/month (100 users)
- **Total Year 1 Revenue: ~$2,500-3,500**

**Net Year 1:** -$1,000 to -$2,000 (acceptable for validation year)

**Year 2 Projection:**
- Start with 100 users ($500/month)
- Grow to 500 users by end of Year 2 ($2,500/month)
- Year 2 revenue: ~$18,000-30,000
- Year 2 costs: ~$10,000-15,000
- **Year 2 Net: +$5,000-20,000 (profitable)**

---

## 🚀 What We Can Do Right Now (Next Week)

### Option 1: Landing Page First (Recommended) 
**Timeline:** 1-2 days
**Cost:** $20-50

**Steps:**
1. **Today:** Register domain (inboxiq.app or inboxiq.co)
2. **Tomorrow:** Build landing page (Carrd.co template)
3. **Day 3:** Write compelling copy
   - Problem: "Email is broken. Too much noise, not enough signal."
   - Solution: "InboxIQ uses AI to organize your inbox automatically."
   - CTA: "Join the waitlist for early access"
4. **Day 4-7:** Share everywhere
   - Reddit: r/productivity, r/email, r/iphone
   - Hacker News: Show HN thread
   - Twitter/LinkedIn: Personal networks
   - Product Hunt: "Coming Soon" page
5. **Day 7:** Review results
   - If 50+ signups → proceed with development
   - If <20 signups → reassess messaging or pivot

**Why Start Here:**
- Validates demand before coding
- Builds waitlist for beta launch
- Costs almost nothing
- Can pivot easily if no interest

---

### Option 2: Build Immediately (Our Current Approach)
**Timeline:** 8-12 weeks
**Cost:** $1,000-2,000

**Steps:**
1. **Week 1-2:** Review docs agents are creating, finalize architecture
2. **Week 3-6:** Development (MVP features only)
   - iOS app (SwiftUI)
   - Backend API (FastAPI)
   - AI integration (Claude)
3. **Week 7:** TestFlight beta (50-100 testers)
4. **Week 8:** Bug fixes, polish
5. **Week 9-10:** App Store submission & review
6. **Week 11:** Launch

**Why This Approach:**
- Faster to market (vs validation first)
- We already have agent architecture
- Docs being created support this path
- Higher risk (no demand validation)

---

### Option 3: Hybrid Approach (Best of Both)
**Timeline:** 2 weeks validation + 8 weeks development
**Cost:** $1,000-2,000

**Steps:**
1. **Week 1:** Build landing page + start user interviews
2. **Week 2:** Share landing page, gather signups, continue interviews
3. **Weeks 3-10:** Build MVP (in parallel with ongoing validation)
4. **Week 11:** Beta launch to waitlist
5. **Week 12-13:** Iterate based on feedback
6. **Week 14:** App Store submission

**Why Hybrid:**
- De-risks development with validation
- Builds waitlist while developing
- User feedback shapes final MVP
- Minimal time delay (2 weeks)

---

## 💰 Realistic First-Year Costs (Ultra-Lean)

| Item | Year 1 Cost | Notes |
|------|-------------|-------|
| **Pre-Launch** | | |
| Domain name | $15 | .app or .co domain |
| Landing page tool | $0-20 | Carrd free or Pro |
| **Development** | | |
| Apple Developer | $99 | Required for App Store |
| Hosting (Railway) | $0-240 | Free tier → $20/month |
| Database (PostgreSQL) | $0 | Included in Railway |
| AI API (Claude) | $600-1,200 | $50-100/month avg |
| **Operations** | | |
| Support tools | $0-300 | Email → Intercom later |
| Analytics | $0-200 | Free tier → paid |
| Monitoring | $0-300 | Sentry after launch |
| **Marketing** | | |
| Apple Search Ads | $500-2,000 | $0-500/month |
| Content/SEO | $0-500 | DIY → contractor |
| **Total** | **$1,214-4,874** | |

**Conservative estimate:** $2,500
**Realistic estimate:** $3,500-4,500
**Aggressive growth:** $6,000-8,000

---

## 🎯 Key Success Metrics (Lean Approach)

### Validation Phase (Months 1-2)
- ✅ 100+ waitlist signups (demand validation)
- ✅ 10+ user interviews completed (problem validation)
- ✅ Clear problem/solution fit confirmed
- ✅ Validated pricing ($4.99-9.99/month)

### MVP Phase (Months 3-4)
- ✅ 50+ TestFlight beta testers
- ✅ 20%+ weekly active usage in beta
- ✅ 4+ star average rating from beta users
- ✅ <3 critical bugs at launch

### Launch Phase (Months 5-6)
- ✅ 10+ paying users in Month 1 post-launch
- ✅ <10% monthly churn
- ✅ App Store rating 4.5+ (public reviews)
- ✅ 5%+ trial-to-paid conversion

### Growth Phase (Months 7-12)
- ✅ 100+ paying users by Month 12
- ✅ $500+ MRR
- ✅ Unit economics: LTV > 3x CAC
- ✅ Growing organically (word-of-mouth)

---

## 🤔 Critical Questions to Answer Before Starting

### 1. Validation Approach
**Question:** Do we validate demand first (landing page) or jump straight to development?

**Option A:** Landing page first (1-2 weeks, $20)
- **Pros:** Low risk, validates demand, builds waitlist
- **Cons:** Delays development by 2 weeks

**Option B:** Build immediately (8 weeks, $1,000)
- **Pros:** Faster to market, we have agent architecture ready
- **Cons:** Higher risk if no demand, wasted resources if pivot needed

**Option C:** Hybrid (2 weeks validation + 8 weeks build in parallel)
- **Pros:** Best of both, minimal delay, de-risked
- **Cons:** More complexity, need to manage both workstreams

**Recommendation:** Option C (Hybrid) - 2 weeks validation overlap with development planning

---

### 2. MVP Feature Scope
**Question:** What's the absolute minimum viable feature set?

**Proposed Minimum:**
- Gmail OAuth login
- AI email categorization (Primary/Social/Promotions/Updates)
- Read, archive, delete emails
- Compose, reply, forward
- Push notifications

**Not in MVP:**
- Multi-account (wait for user feedback)
- Snooze (nice-to-have, not essential)
- Send later (can add in Phase 2)
- Templates (Phase 2 feature)
- Calendar integration (Phase 2+)

**Question:** Is this enough to charge $4.99/month? Or do we need more?

**Recommendation:** Ship this MVP, gather feedback, add most-requested features in Phase 2

---

### 3. Pricing Strategy
**Question:** What should we charge?

**Option A:** $4.99/month (lower barrier)
- **Pros:** Easier adoption, more users, faster growth
- **Cons:** Lower margins, need more users to break even

**Option B:** $9.99/month (target price)
- **Pros:** Better margins, fewer users needed for sustainability
- **Cons:** Harder to convince users to try, higher churn risk

**Option C:** Free tier + $9.99 Pro
- **Pros:** Freemium = more total users, upsell path
- **Cons:** Higher infrastructure costs, conversion risk

**Recommendation:** Start at $4.99/month (7-day trial), increase to $9.99 in Phase 2 when we add more features

---

### 4. Free Tier or Paid-Only?
**Question:** Should we offer a free tier?

**Free Tier (Freemium Model):**
- **Pros:** More users, viral growth, upsell opportunities
- **Cons:** Higher costs (AI + infrastructure for free users), 95%+ never convert

**Paid-Only (7-Day Trial):**
- **Pros:** Only paying users, better unit economics, sustainable from day 1
- **Cons:** Smaller user base, harder initial growth

**Recommendation:** Paid-only with 7-day free trial (no credit card required). Add free tier in Phase 3 if needed for growth.

---

### 5. Launch Strategy
**Question:** TestFlight beta or straight to App Store?

**TestFlight Beta First:**
- **Pros:** Real user feedback, fix bugs before public launch, build buzz
- **Cons:** Delays revenue by 2-4 weeks, limited to 10,000 testers

**Straight to App Store:**
- **Pros:** Faster to revenue, public visibility immediately
- **Cons:** Public bugs, bad reviews if not polished

**Recommendation:** TestFlight beta with 50-100 waitlist users for 2-4 weeks, then App Store launch

---

### 6. Development Approach
**Question:** Custom build (Option B) or no-code prototype (Option A)?

**Custom Build (Swift + FastAPI):**
- **Pros:** Full control, better UX, scalable, we have agents ready
- **Cons:** 8+ weeks development, more complex

**No-Code (Glide/FlutterFlow + n8n):**
- **Pros:** 2-4 weeks to ship, easier iteration, lower complexity
- **Cons:** Platform limitations, harder to scale, less native feel

**Recommendation:** Custom build (we have the agent architecture, might as well use it). If timelines slip, pivot to no-code.

---

## 📋 Decision Framework

**Answer these to finalize approach:**

1. **Budget:** How much can ClearPointLogic invest upfront? ($1K, $3K, $5K, $10K?)
2. **Timeline:** How fast do we need revenue? (3 months, 6 months, 12 months?)
3. **Risk tolerance:** Validate first (lower risk) or build first (faster but riskier)?
4. **Resource availability:** Can our agent architecture handle this in parallel with other work?
5. **Strategic priority:** Is InboxIQ the #1 priority, or one of several bets?

**Based on answers, choose:**
- **Conservative path:** Validation → MVP → Launch (lowest risk, ~4 months, $2K)
- **Balanced path:** Hybrid validation + MVP → Launch (medium risk, ~3 months, $3K)
- **Aggressive path:** Build MVP → Launch → Iterate (higher risk, ~2 months, $4K)

---

## ✅ Next Steps (After V Reviews)

1. **V reviews this doc** + all 10 agent-created documents
2. **Decision meeting:** Answer 6 critical questions above
3. **Finalize approach:** Conservative, Balanced, or Aggressive
4. **Create sprint plan:** Week-by-week tasks and owners
5. **Kick off Week 1:** Either landing page OR development OR both

---

## 🎁 Bonus: What If We Fail?

**Failure = Learning. Here's what we gain even if InboxIQ doesn't work:**

1. **Agent architecture validated** (or improved) - reusable for future projects
2. **iOS development experience** - team learns Swift/SwiftUI
3. **AI integration expertise** - Claude API, categorization, embeddings
4. **Go-to-market practice** - landing pages, App Store, user interviews
5. **Product thinking** - what users want vs what we think they want
6. **Financial discipline** - managing costs, unit economics, break-even analysis

**Pivot options if InboxIQ doesn't work:**
- Apply same architecture to different problem (calendar, tasks, notes)
- White-label the tech for enterprise clients
- Open-source parts of it, build reputation
- Extract reusable components (AI categorization SDK)

**Bottom line:** Even "failure" builds valuable assets for ClearPointLogic.

---

**Created:** 2026-02-23
**Author:** Shiv 🔥
**Purpose:** Alternate lean launch strategy for InboxIQ - start small, validate, grow smart
**Status:** Awaiting V's review and decision on approach
