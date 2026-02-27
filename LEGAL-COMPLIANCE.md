# InboxIQ Legal & Compliance Guide
**Last Updated:** February 23, 2026  
**Status:** Template - Requires Attorney Review  
**Product:** InboxIQ Email App for iOS  

---

## ⚖️ Executive Summary

InboxIQ handles highly sensitive user data (emails, contacts, calendar) and must comply with:
- **GDPR** (EU users) - Strict data protection requirements
- **CCPA** (California users) - Privacy rights and data disclosure
- **Apple App Store Guidelines** - Privacy, data handling, subscription rules
- **Email Provider Policies** - Gmail API, Microsoft Graph, iCloud Mail
- **COPPA** (if allowing users under 13) - Currently recommend 13+ only

**🚨 CRITICAL:** All templates below require attorney review before use.

---

## 📋 Compliance Checklist

### Pre-Launch Requirements
- [ ] Register as data controller with relevant EU authorities
- [ ] Appoint Data Protection Officer (DPO) if processing large-scale data
- [ ] Create privacy@inboxiq.com support email
- [ ] Set up data deletion request system
- [ ] Implement consent management system
- [ ] Create data breach response plan
- [ ] Purchase cyber liability insurance
- [ ] **Attorney Review:** All legal documents

### App Store Requirements
- [ ] Privacy Policy URL (required for submission)
- [ ] Privacy nutrition labels completed accurately
- [ ] Encryption export compliance (ERN if needed)
- [ ] Age rating set appropriately (12+ recommended)
- [ ] In-app purchase disclosures accurate

### Email Provider Compliance
- [ ] Gmail API verification process completed
- [ ] Microsoft Graph API permissions justified
- [ ] OAuth scopes limited to necessary minimum
- [ ] Privacy policy meets provider requirements
- [ ] Data usage disclosure accurate

---

## 1. 📄 Privacy Policy Template

**[ATTORNEY REVIEW REQUIRED]**

### INBOXIQ PRIVACY POLICY

**Effective Date:** [Date]

#### 1. Introduction
InboxIQ ("we," "our," or "us") respects your privacy and is committed to protecting your personal data. This privacy policy explains how we collect, use, and safeguard your information when you use our email application.

#### 2. Information We Collect

**Account Information:**
- Email address (required for account creation)
- Name (optional)
- Profile photo (optional)
- Payment information (Pro/Team subscriptions)

**Email Data:**
- Email content (messages, attachments)
- Email metadata (sender, recipient, timestamps)
- Contact information from your address book
- Calendar data (when integrated)

**Usage Data:**
- Feature usage patterns
- Response times and email habits
- App performance metrics
- Device information (iOS version, device model)

**AI Processing Data:**
- Email categorization preferences
- Smart compose patterns
- Custom rules and filters

#### 3. How We Use Your Information

**Primary Uses:**
- Provide email services
- Sync emails across devices
- AI-powered features (categorization, smart replies)
- Send notifications
- Process payments

**We DO NOT:**
- Read your emails for advertising
- Sell your data to third parties
- Share email content without consent
- Use email data for purposes beyond app functionality

#### 4. Data Storage & Security

**Storage:**
- Emails cached locally on device (encrypted)
- Metadata stored in secure cloud database (PostgreSQL)
- Attachments in encrypted S3 storage
- EU data stored in EU data centers

**Security Measures:**
- End-to-end encryption for sensitive data
- TLS encryption in transit
- AES-256 encryption at rest
- Regular security audits
- Two-factor authentication available

#### 5. Third-Party Services

**Email Providers:**
- Gmail (via OAuth 2.0)
- Microsoft (via Microsoft Graph)
- iCloud Mail
- Generic IMAP/SMTP providers

**Service Providers:**
- Claude AI (Anthropic) - Email categorization and smart features
- Railway/Fly.io - Infrastructure hosting
- Amazon S3 - Attachment storage
- Stripe - Payment processing

**Data Shared:** Only minimum necessary for functionality

#### 6. Your Rights (GDPR/CCPA)

**You have the right to:**
- **Access** your personal data
- **Rectify** inaccurate data
- **Delete** your account and data
- **Export** your data (portability)
- **Object** to certain processing
- **Restrict** processing
- **Withdraw consent** at any time

**Exercise rights:** privacy@inboxiq.com

#### 7. Data Retention

- **Active accounts:** Data retained while account active
- **Deleted emails:** Removed within 30 days
- **Closed accounts:** Data deleted within 90 days
- **Backups:** Purged within 6 months
- **Legal holds:** As required by law

#### 8. Children's Privacy

- Service intended for users 13 and older
- We do not knowingly collect data from children under 13
- Parents may contact us to delete child's data

#### 9. International Data Transfers

- EU → US transfers use Standard Contractual Clauses
- We comply with EU-US data transfer requirements
- You may request data remain in your region

#### 10. Changes to Privacy Policy

- Users notified of material changes via email
- Continued use constitutes acceptance
- Previous versions available upon request

#### 11. Contact Information

**Data Controller:** InboxIQ, Inc.  
**Email:** privacy@inboxiq.com  
**DPO:** [Name if appointed]  
**Address:** [Company Address]

---

## 2. 📜 Terms of Service Template

**[ATTORNEY REVIEW REQUIRED]**

### INBOXIQ TERMS OF SERVICE

**Effective Date:** [Date]

#### 1. Acceptance of Terms
By using InboxIQ, you agree to these Terms of Service. If you disagree, do not use the service.

#### 2. Service Description
InboxIQ provides email management services including:
- Email synchronization
- AI-powered organization
- Multi-account support
- Collaboration features (Team plans)

#### 3. Account Registration
- You must provide accurate information
- You are responsible for account security
- One person per account (no sharing)
- Must be 13 or older

#### 4. Acceptable Use
**You agree NOT to:**
- Violate any laws or regulations
- Send spam or unsolicited emails
- Impersonate others
- Attempt to access other users' data
- Reverse engineer the service
- Use for illegal or harmful purposes

#### 5. Subscription & Payment
- **Free tier:** Limited features, no payment required
- **Paid tiers:** Monthly/annual subscription
- **Auto-renewal:** Unless cancelled
- **Refunds:** Within 14 days of purchase
- **Price changes:** 30 days notice

#### 6. Intellectual Property
- We retain rights to InboxIQ service
- You retain rights to your email content
- You grant us license to process emails for service functionality
- Feedback may be used without compensation

#### 7. Privacy & Data
- Governed by our Privacy Policy
- You consent to email processing for app features
- We don't read emails for advertising

#### 8. Service Availability
- Target 99.9% uptime (no guarantee)
- Maintenance windows with notice
- No liability for third-party service outages

#### 9. Limitation of Liability
- Service provided "AS IS"
- No warranty of uninterrupted service
- Not liable for data loss (maintain backups)
- Maximum liability: Amount paid in last 12 months

#### 10. Indemnification
You indemnify InboxIQ against claims arising from:
- Your use of the service
- Violation of these terms
- Infringement of third-party rights

#### 11. Termination
- Either party may terminate at any time
- We may suspend for terms violations
- Data available for export for 90 days post-termination

#### 12. Governing Law
- Governed by [State] law
- Disputes resolved in [County] courts
- Mandatory arbitration for claims under $10,000

#### 13. Changes to Terms
- We may update terms with 30 days notice
- Continued use constitutes acceptance
- Material changes require explicit consent

#### 14. Contact
**Support:** support@inboxiq.com  
**Legal:** legal@inboxiq.com

---

## 3. 📱 App Store Compliance Requirements

### Privacy Requirements
- [x] **Privacy Policy URL** - Required for submission
- [x] **Data Collection Disclosure** - Must declare all data types
- [x] **Purpose Disclosure** - Explain why each data type needed

### App Store Privacy Labels
**Data Linked to You:**
- Email Address (Account management)
- Name (Optional profile)
- Email messages (Core functionality)
- Contacts (Email addressing)
- Payment info (Subscriptions)
- Usage data (Analytics)

**Data NOT Linked to You:**
- Crash logs
- Performance metrics

### Required Implementations
- [ ] **Request Tracking Permission** (if using any tracking)
- [ ] **Sign in with Apple** (required if offering third-party login)
- [ ] **Subscription Management** - Easy cancel/manage in app
- [ ] **Restore Purchases** - Required for subscriptions
- [ ] **Privacy Prompt Explanations** - Clear purpose strings

### Common Rejection Reasons to Avoid
- ❌ Accessing contacts without clear explanation
- ❌ Unclear data usage in privacy policy
- ❌ Missing account deletion option
- ❌ Subscription terms not clear before purchase
- ❌ Using email data for undisclosed purposes

---

## 4. 📧 Email Provider Policy Compliance

### Gmail API (Google)
**Requirements:**
- [ ] API Services User Data Policy compliance
- [ ] Limited Use requirements
- [ ] OAuth consent screen verified
- [ ] Privacy policy meets Google standards
- [ ] Annual security assessment (if 100K+ users)

**Restricted Scopes We Need:**
- `gmail.modify` - Read, compose, send email
- `gmail.send` - Send email on behalf
- `contacts.readonly` - Read contacts

**Compliance Notes:**
- Display Google Sign-in branding correctly
- Clear disclosure of data usage
- Implement secure OAuth flow
- Regular security reviews required

### Microsoft Graph API
**Requirements:**
- [ ] Microsoft 365 App Compliance Program
- [ ] Publisher verification completed
- [ ] Admin consent for organizational data
- [ ] Least privilege permissions

**Permissions Needed:**
- `Mail.ReadWrite` - Email access
- `Calendars.Read` - Calendar integration
- `Contacts.Read` - Address book

### iCloud Mail
**Requirements:**
- [ ] Standard IMAP/SMTP compliance
- [ ] App-specific passwords supported
- [ ] Two-factor authentication compatible

---

## 5. 🗄️ Data Retention Policies

### Email Data
- **Active emails:** Retained while account active
- **Deleted emails:** Soft delete for 30 days, then permanent
- **Archived emails:** Retained indefinitely unless user deletes
- **Attachments:** Same as parent email

### Account Data
- **Active accounts:** All data retained
- **Inactive (12 months):** Warning sent, then deletion
- **Deleted accounts:** 90-day recovery period, then permanent deletion

### AI Training Data
- **Personal patterns:** Retained while account active
- **Aggregated insights:** Anonymized and retained
- **Custom rules:** Deleted with account

### Backup Policies
- **Frequency:** Daily incremental, weekly full
- **Retention:** 30 days for active accounts
- **Disaster recovery:** Separate geographic region
- **Encryption:** AES-256 at rest

**[ATTORNEY NOTE: Confirm retention periods comply with legal requirements]**

---

## 6. 🍪 Cookie & Tracking Disclosure

### Web App Cookies
**Essential Cookies:**
- Session management
- Authentication tokens
- Security features

**Analytics Cookies (with consent):**
- Usage patterns
- Feature adoption
- Performance metrics

**No Third-Party Advertising Cookies**

### Mobile App Tracking
- **Analytics:** App usage, crash reports
- **No IDFA collection** unless user opts in
- **No cross-app tracking**
- **No sale of tracking data**

### Email Tracking
- **Optional read receipts** (user control)
- **Link click tracking** (Pro feature, optional)
- **Pixel blocking** available for privacy

---

## 7. 👶 Children's Privacy (COPPA)

### Current Policy: 13+ Only
- Terms require users be 13 or older
- No directed marketing to children
- No collection from known children

### If Allowing Under 13 (Future):
**[ATTORNEY REVIEW CRITICAL]**
- [ ] Parental consent system
- [ ] Verifiable parental consent
- [ ] Limited data collection
- [ ] No behavioral advertising
- [ ] Parental access rights
- [ ] Enhanced security measures

**Recommendation:** Maintain 13+ requirement to avoid COPPA complexity

---

## 8. 🚨 Data Breach Notification Procedures

### Incident Response Plan
1. **Detection** (0-4 hours)
   - Identify breach scope
   - Contain the breach
   - Preserve evidence

2. **Assessment** (4-24 hours)
   - Determine data affected
   - Identify users impacted
   - Assess harm risk

3. **Notification** (24-72 hours)
   - **GDPR:** Within 72 hours to authorities
   - **Users:** Without undue delay if high risk
   - **Partners:** Per contractual obligations

### Notification Template
**[ATTORNEY REVIEW REQUIRED]**

Subject: Important Security Update Regarding Your InboxIQ Account

We recently discovered a security incident affecting some InboxIQ accounts, including yours.

**What Happened:** [Brief description]
**When:** [Date range]
**Data Affected:** [Specific data types]
**Actions Taken:** [Our response]
**Your Actions:** [Recommended steps]

Contact: security@inboxiq.com

### Post-Breach
- Forensic analysis
- Security improvements
- Regulatory compliance
- User support

---

## 9. 🔑 User Rights Implementation

### Access Rights (GDPR Article 15)
**Implementation:**
- Self-service data export in settings
- Full export includes emails, metadata, settings
- Format: Standard (mbox) + JSON
- Delivery within 30 days

### Deletion Rights (Right to Erasure)
**Implementation:**
- Account deletion in settings
- 30-day recovery period
- Complete deletion after recovery
- Confirmation email required

### Portability Rights
**Formats Provided:**
- Emails: mbox format
- Contacts: vCard
- Settings: JSON
- Attachments: ZIP archive

### Objection/Restriction Rights
**Options:**
- Disable AI processing
- Limit data to essential only
- Pause account vs deletion
- Granular consent management

### Implementation Checklist
- [ ] Build privacy rights dashboard
- [ ] Automated export system
- [ ] Deletion queue system
- [ ] Audit trail for compliance
- [ ] Support team training

---

## 10. 🤝 Third-Party Vendor Agreements

### Critical Vendor Requirements

#### Claude AI (Anthropic)
**Data Processing Terms Needed:**
- [ ] GDPR compliance confirmation
- [ ] Data residency options
- [ ] Deletion requirements
- [ ] No training on user data
- [ ] Security certifications

**[ATTORNEY NOTE: Review Anthropic's DPA carefully]**

#### Infrastructure (Railway/Fly.io)
**Requirements:**
- [ ] SOC 2 Type II certification
- [ ] GDPR-compliant DPA
- [ ] Data residency control
- [ ] Incident notification SLA
- [ ] Right to audit

#### Payment (Stripe)
**Already Compliant:**
- PCI DSS Level 1
- Strong GDPR compliance
- Standard DPA available

### Vendor Checklist
- [ ] Data Processing Agreements signed
- [ ] Security assessments completed
- [ ] GDPR compliance verified
- [ ] Sub-processor list maintained
- [ ] Annual reviews scheduled

---

## 11. 🌍 International Compliance

### GDPR (European Union)
- [x] Lawful basis identified (consent + legitimate interest)
- [ ] Privacy by Design implemented
- [ ] Data Protection Impact Assessment (if high risk)
- [ ] Representative appointed (if no EU presence)
- [ ] Standard Contractual Clauses for transfers

### CCPA (California)
- [x] "Do Not Sell" not applicable (we don't sell data)
- [ ] Privacy Rights page created
- [ ] Opt-out mechanisms implemented
- [ ] Service provider agreements updated
- [ ] Employee training completed

### Other Jurisdictions
- **UK GDPR:** Similar to EU GDPR
- **Canada PIPEDA:** Consent and disclosure requirements
- **Australia Privacy Act:** APP compliance needed
- **Brazil LGPD:** Similar to GDPR

**[ATTORNEY NOTE: Assess need for local counsel in key markets]**

---

## 12. ⚠️ High-Priority Legal Review Items

### Immediate Attorney Review Needed
1. **Privacy Policy** - Full review and localization
2. **Terms of Service** - Enforceability check
3. **DPAs** - Third-party agreements
4. **Arbitration Clause** - Validity by jurisdiction
5. **Minor Protections** - COPPA compliance
6. **Data Breach Plan** - Legal requirements

### Compliance Risks
1. **Email Content Processing** - Ensure clear consent
2. **AI Training** - No use of user data without permission
3. **Cross-Border Transfers** - GDPR compliance
4. **Health Information** - May be in emails (HIPAA?)
5. **Financial Information** - PCI DSS if storing cards

### Recommended Legal Actions
1. **Retain Privacy Counsel** - Specialized in SaaS/email
2. **Register Trademarks** - "InboxIQ" and logo
3. **Insurance Review** - Cyber liability coverage
4. **Regular Audits** - Annual compliance check
5. **Incident Response Retainer** - Have counsel ready

---

## 📝 Document Control

**Version:** 1.0 (Template)  
**Created:** February 23, 2026  
**Author:** Legal Compliance Subagent  
**Status:** REQUIRES ATTORNEY REVIEW  
**Next Review:** Before launch

### Revision History
- v1.0 - Initial template created

### Related Documents
- `/projects/inboxiq/COMPREHENSIVE-FEATURES.md`
- `/projects/inboxiq/privacy-policy.html` (when created)
- `/projects/inboxiq/terms-of-service.html` (when created)

---

**⚡ CRITICAL REMINDER:** This is a template based on best practices and common requirements. Professional legal counsel MUST review and adapt all documents before use. Email apps handle highly sensitive data and face significant regulatory scrutiny.