# InboxIQ Backend API Documentation

## Authentication

All authenticated endpoints require a Bearer token in the Authorization header:
```
Authorization: Bearer <jwt_token>
```

## Core Endpoints

### Authentication
- `POST /auth/login` - Initial OAuth flow
- `POST /auth/refresh` - Refresh JWT token
- `POST /auth/logout` - Revoke tokens

### Email Operations
- `GET /emails` - List emails (paginated)
- `GET /emails/{id}` - Get single email
- `POST /emails/sync` - Trigger manual sync
- `PATCH /emails/{id}` - Update category
- `DELETE /emails/{id}` - Delete email

### Categories
- `GET /categories` - List all categories
- `POST /categories` - Create custom category
- `PATCH /categories/{id}` - Update category
- `DELETE /categories/{id}` - Delete category

### Push Notifications
- `POST /push/register` - Register device token
- `DELETE /push/unregister` - Remove device token

### Daily Digest
- `GET /digest/settings` - Get user's digest settings
- `PUT /digest/settings` - Update digest settings
- `GET /digest/history` - Get past digests
- `POST /digest/test` - Send test digest immediately
- `GET /digest/preview` - Preview next digest

---

## Action Endpoints

### Execute Email Action
`GET /actions/{action_token}`

Public endpoint that executes an email action using a secure token from a digest email.

**Parameters:**
- `action_token` (path) - Single-use action token from digest email

**Responses:**
- `200 OK` - HTML success page ("✅ Email archived successfully!")
- `400 Bad Request` - Invalid, expired, or already-used token
- `404 Not Found` - Email or user not found
- `500 Internal Server Error` - Gmail API error

**Security:**
- Tokens expire after 48 hours
- Single-use only (cannot be reused)
- Cryptographically signed (JWT)

**Example Flow:**
1. User receives digest email with action link
2. Clicks "Archive" button
3. Browser opens: `https://api.inboxiq.com/actions/eyJhbGci...`
4. Backend validates token, archives email in Gmail
5. User sees success page: "✅ Email archived! You can close this tab."

**Supported Actions:**
- `archive` - Removes email from inbox
- `delete` - Moves email to trash
- `reply` - Redirects to Gmail compose

**Error Handling:**
- Expired token → "This link has expired"
- Already used → "This link has already been used"
- Invalid signature → "Invalid action link"

**Technical Details:**

The action endpoint is intentionally public (no Bearer auth) to allow clicking links from email clients. Security is provided by:

1. **JWT Signature**: Token is cryptographically signed
2. **Expiration**: 48-hour time limit embedded in token
3. **Single-use**: Database tracking prevents reuse
4. **User Binding**: Token encodes user_id, validated before action

**Example Token Payload:**
```json
{
  "sub": "user-uuid-here",
  "email_id": 12345,
  "action": "archive",
  "exp": 1709251200,
  "type": "action"
}
```

**Response Examples:**

Success (200 OK):
```html
<!DOCTYPE html>
<html>
<head>
  <title>Success</title>
  <style>/* Mobile-responsive styles */</style>
</head>
<body>
  <div class="success">
    <h1>✅ Email archived successfully!</h1>
    <p>You can close this tab.</p>
  </div>
</body>
</html>
```

Error (400 Bad Request):
```html
<!DOCTYPE html>
<html>
<head>
  <title>Link Expired</title>
  <style>/* Mobile-responsive styles */</style>
</head>
<body>
  <div class="error">
    <h1>⏱️ This link has expired</h1>
    <p>Action links work for 48 hours. Please use the InboxIQ app to manage this email.</p>
  </div>
</body>
</html>
```

## Webhooks

### Gmail Push Notifications
`POST /webhooks/gmail` - Receive Gmail push notifications

---

## Rate Limits

All authenticated endpoints are rate-limited:
- 100 requests per minute per user
- Sync endpoint: 10 requests per minute

## Error Responses

All errors follow this format:
```json
{
  "error": "error_code",
  "message": "Human-readable message",
  "details": {}
}
```

Common error codes:
- `authentication_required` - Missing or invalid token
- `rate_limit_exceeded` - Too many requests
- `invalid_request` - Validation failed
- `resource_not_found` - Entity doesn't exist
- `gmail_api_error` - Upstream Gmail error
