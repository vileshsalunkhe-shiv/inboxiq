# Changelog

All notable changes to InboxIQ will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Email Action Links in Digests** - Users can now Archive, Delete, or Reply to emails directly from daily digest emails via secure, single-use action links. Links expire after 48 hours and work on all devices. Reduces friction for common email actions.

### Technical
- New `action_tokens` database table for secure action link storage
- New endpoint: `GET /actions/{action_token}` for executing email actions
- Enhanced digest email template with styled action buttons
- JWT-based single-use token system with 48-hour expiration
- HTML success/error pages for user feedback
- Token validation with cryptographic signatures
- Automatic cleanup of expired tokens via daily cron job

## [0.1.0] - 2024-02-XX (Initial MVP)

### Added
- Gmail OAuth 2.0 authentication flow
- Email sync engine with delta sync support
- AI-powered email categorization using Claude 3 Haiku
- Daily digest emails with category summaries
- Pull-to-refresh email sync
- Background fetch for silent updates
- Core Data caching for offline access
- Push notification support
- Category management (view, create, edit, delete)
- Digest settings (frequency, timezone, content preferences)

### Technical
- FastAPI backend with async Python
- PostgreSQL database with partitioning
- Redis for caching and rate limiting
- Simple Python worker for AI processing
- APScheduler for digest generation
- SwiftUI iOS application
- Sentry error tracking
- Structured logging with contextual metadata
- Railway deployment configuration

### Security
- JWT authentication with refresh tokens
- Encrypted storage of Gmail refresh tokens
- Rate limiting on all authenticated endpoints
- Privacy-first architecture (minimal data retention)

---

## Version History

- **[Unreleased]** - Email Action Links feature
- **0.1.0** - Initial MVP release
