# Error Handling & Response Guide

**Aurora API: Error Response Standards**

---

## HTTP Status Codes

### Success Responses
- **200 OK** - Request successful, returning data
- **201 Created** - Resource successfully created
- **204 No Content** - Request successful, no content in response

### Client Error Responses
- **400 Bad Request** - Invalid request parameters or body
  - Example: `{"error": "Invalid parameter: limit must be between 1 and 50"}`

- **401 Unauthorized** - Missing or invalid JWT token
  - Example: `{"error": "Missing or invalid JWT token. Provide token in Authorization header: Bearer <token>"}`

- **403 Forbidden** - User lacks permission for this resource
  - Example: `{"error": "You cannot delete posts by other users"}`

- **404 Not Found** - Resource not found or not visible
  - Example: `{"error": "Post not found or not visible to you"}`

- **429 Too Many Requests** - Rate limit exceeded
  - Example: `{"error": "Rate limit exceeded. Max 30 actions per minute. Please retry after 60 seconds."}`

### Server Error Responses
- **500 Internal Server Error** - Unexpected server error
  - Example: `{"error": "An unexpected error occurred. Please try again later. Error ID: abc123"}`

- **503 Service Unavailable** - Temporary service unavailability
  - Example: `{"error": "External service temporarily unavailable. Please retry in 30 seconds."}`

---

## Input Validation Errors

### Chat Endpoint Validation

**POST /chat/message**
```json
{
  "message": "..."  // min 1, max 2000 chars
}
```

**Error Cases:**
- Empty message: `400 Bad Request - "Message cannot be empty"`
- Too long: `400 Bad Request - "Message exceeds 2000 character limit (provided: X)"`
- Invalid JSON: `400 Bad Request - "Invalid JSON in request body"`

### Post Endpoint Validation

**POST /social/posts**
```json
{
  "content": "...",        // min 1, max 2000 chars (required)
  "image_urls": [...],     // max 5 images
  "strain_tag": "...",     // optional
  "grow_id": "...",        // optional UUID
  "day_number": 0          // optional, >= 0
}
```

**Error Cases:**
- Empty content: `400 Bad Request - "Post content cannot be empty"`
- Too long: `400 Bad Request - "Post content exceeds 2000 character limit (provided: X)"`
- Too many images: `400 Bad Request - "Maximum 5 images allowed (provided: X)"`
- Invalid grow_id: `400 Bad Request - "Invalid UUID format for grow_id"`
- Negative day_number: `400 Bad Request - "day_number cannot be negative"`

### Comment Endpoint Validation

**POST /social/posts/{post_id}/comments**
```json
{
  "content": "...",  // min 1, max 500 chars
  "grow_id": "..."   // optional
}
```

**Error Cases:**
- Empty content: `400 Bad Request - "Comment cannot be empty"`
- Too long: `400 Bad Request - "Comment exceeds 500 character limit (provided: X)"`
- Post not found: `404 Not Found - "Post not found or not visible to you"`

### Report Endpoint Validation

**POST /social/reports**
```json
{
  "reason": "...",     // min 1, max 500 chars
  "post_id": "...",    // optional UUID
  "comment_id": "..."  // optional UUID
}
```

**Error Cases:**
- Empty reason: `400 Bad Request - "Report reason cannot be empty"`
- Too long: `400 Bad Request - "Report reason exceeds 500 character limit (provided: X)"`
- Missing target: `400 Bad Request - "Must provide either post_id or comment_id"`

---

## Pagination Errors

**GET /social/feed, /social/posts, etc.**
```
Query Parameters:
  - page: int >= 1 (default: 1)
  - limit: int between 1-50 (default: 20)
  - skip: int >= 0 (computed from page/limit)
```

**Error Cases:**
- Invalid page: `400 Bad Request - "page must be >= 1, provided: X"`
- Invalid limit: `400 Bad Request - "limit must be between 1 and 50, provided: X"`
- Negative skip: `400 Bad Request - "skip cannot be negative"`

---

## Authentication Errors

**Missing or Invalid Token**
```
401 Unauthorized
{
  "error": "Missing or invalid JWT token",
  "detail": "Provide token in Authorization header: Bearer <token>",
  "code": "AUTH_001"
}
```

**Token Expired**
```
401 Unauthorized
{
  "error": "Token expired",
  "detail": "Please refresh your token using POST /auth/refresh",
  "code": "AUTH_002"
}
```

**Token Invalid Signature**
```
401 Unauthorized
{
  "error": "Invalid token signature",
  "detail": "Token appears corrupted or tampered with",
  "code": "AUTH_003"
}
```

---

## Rate Limiting Errors

**Rate Limit Exceeded**
```
429 Too Many Requests
{
  "error": "Rate limit exceeded",
  "detail": "Max 30 actions per minute",
  "retry_after_seconds": 60,
  "current_usage": 30,
  "code": "RATE_001"
}
```

---

## Database/Service Errors

**Connection Timeout**
```
503 Service Unavailable
{
  "error": "Database connection timeout",
  "detail": "Please retry your request in 30 seconds",
  "code": "DB_001"
}
```

**Unexpected Error**
```
500 Internal Server Error
{
  "error": "An unexpected error occurred",
  "error_id": "5f8c3a2b-1234-5678-9abc-def0123456789",
  "code": "SERVER_001",
  "detail": "Please contact support with error ID: 5f8c3a2b-1234-5678-9abc-def0123456789"
}
```

---

## Content Moderation Errors

**Toxicity Detected**
```
400 Bad Request
{
  "error": "Content violates community guidelines",
  "detail": "Post contains toxic language. Please revise and resubmit.",
  "code": "MOD_001",
  "blocked_keywords": ["example1", "example2"]
}
```

**Auto-Moderation (non-critical)**
```
// Post created but hidden
201 Created
{
  "id": "post_id",
  "status": "created_but_hidden",
  "warning": "Post was auto-hidden due to potential guideline violations. It will be reviewed by moderators.",
  "visible": false
}
```

---

## Error Response Format

**Standard Format:**
```json
{
  "error": "Brief error message",
  "detail": "Detailed explanation (optional)",
  "code": "ERROR_CODE",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**With Additional Context:**
```json
{
  "error": "Validation failed",
  "details": [
    { "field": "content", "message": "Cannot be empty" },
    { "field": "limit", "message": "Must be between 1 and 50" }
  ],
  "code": "VALIDATION_001"
}
```

---

## Error Codes Reference

| Code | HTTP | Description |
|------|------|-------------|
| AUTH_001 | 401 | Missing/invalid token |
| AUTH_002 | 401 | Token expired |
| AUTH_003 | 401 | Invalid token signature |
| VAL_001 | 400 | Validation error |
| VAL_002 | 400 | Invalid parameter type |
| VAL_003 | 400 | Required field missing |
| RATE_001 | 429 | Rate limit exceeded |
| NOT_FOUND_001 | 404 | Resource not found |
| PERM_001 | 403 | Permission denied |
| MOD_001 | 400 | Content moderation blocked |
| DB_001 | 503 | Database error |
| EXT_001 | 503 | External service error |
| SERVER_001 | 500 | Internal server error |

---

## Best Practices for Error Handling

1. **Always include error code** - Allows clients to programmatically handle errors
2. **Provide actionable detail** - Tell users HOW to fix the error
3. **Include context in 500 errors** - Provide error ID for support tickets
4. **Don't expose internal details** - Hide implementation details in error messages
5. **Be consistent** - Use same format across all endpoints
6. **Log for debugging** - Server logs should include full stack traces
7. **Rate limit gracefully** - Tell clients when they can retry
8. **Handle edge cases** - Special characters, Unicode, very long inputs

---

## Examples

### ✅ Good Error Message
```json
{
  "error": "Validation failed",
  "detail": "Post content exceeds 2000 character limit. Provided: 2,145 characters. Please reduce to 2000 or less.",
  "code": "VAL_001"
}
```

### ❌ Bad Error Message
```json
{
  "error": "Bad request"
}
```

### ✅ Good Error Message
```json
{
  "error": "Rate limit exceeded",
  "detail": "You have used 30 of your 30 allowed actions this minute. Please retry after 60 seconds.",
  "code": "RATE_001",
  "retry_after_seconds": 60
}
```

### ❌ Bad Error Message
```json
{
  "error": "429"
}
```
