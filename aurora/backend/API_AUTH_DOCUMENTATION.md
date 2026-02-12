# Aurora Auth Endpoints API Documentation

**Base URL:** `/auth`  
**Authentication:** Optional (endpoints provide tokens)  
**Rate Limiting:** 100 requests/minute per email

---

## Overview

The Auth endpoints provide user registration, login, token refresh, and logout functionality. Authentication uses JWT tokens via Supabase Auth.

**Token Structure:**
- **Access Token (JWT):** 3600 seconds validity (1 hour)
- **Refresh Token (Opaque):** Long-lived, used to obtain new access tokens
- **Format:** Bearer token in `Authorization` header

---

## Endpoints

### 1. POST /auth/signup

Register a new user account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "display_name": "John Grower",
  "role": "grower"
}
```

**Query Parameters:** None

**Request Headers:** None required

**Response (201 Created):**
```json
{
  "id": "uuid-12345678",
  "email": "user@example.com",
  "display_name": "John Grower",
  "role": "grower",
  "created_at": "2024-01-15T10:30:00Z",
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "refresh_token_opaque_string",
  "expires_in": 3600,
  "token_type": "Bearer"
}
```

**Validation Rules:**
- `email`: Must be valid email format and unique
- `password`: 8-128 characters
- `display_name`: 1-50 characters (required)
- `role`: Optional, defaults to "grower" (values: "grower", "breeder", "distributor")

**Possible Errors:**

| Status | Error Code | Description |
|--------|-----------|-------------|
| 400 | AUTH_EMAIL_EXISTS | Email already registered |
| 400 | VAL_001 | Invalid email format |
| 400 | VAL_002 | Password too short (< 8 chars) |
| 400 | VAL_003 | Display name invalid |
| 500 | AUTH_CREATE_FAILED | Failed to create account |
| 500 | AUTH_SIGNUP_ERROR | Unexpected error |

**Example Error Response:**
```json
{
  "error": "Email already registered",
  "detail": "The email user@example.com is already associated with an account",
  "code": "AUTH_EMAIL_EXISTS"
}
```

**Curl Example:**
```bash
curl -X POST "http://localhost:8000/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "password": "SecurePass123!",
    "display_name": "Jane Grower"
  }'
```

---

### 2. POST /auth/login

Authenticate user and obtain access token.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

**Query Parameters:** None

**Request Headers:** None required

**Response (200 OK):**
```json
{
  "id": "uuid-12345678",
  "email": "user@example.com",
  "display_name": "John Grower",
  "role": "grower",
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "refresh_token_opaque_string",
  "expires_in": 3600,
  "token_type": "Bearer"
}
```

**Validation Rules:**
- `email`: Must be valid email format
- `password`: Must match stored password

**Possible Errors:**

| Status | Error Code | Description |
|--------|-----------|-------------|
| 401 | AUTH_INVALID_CREDENTIALS | Email or password incorrect |
| 404 | AUTH_PROFILE_NOT_FOUND | User profile missing |
| 500 | AUTH_LOGIN_ERROR | Unexpected error |

**Example Error Response:**
```json
{
  "error": "Invalid credentials",
  "detail": "Email or password is incorrect",
  "code": "AUTH_INVALID_CREDENTIALS"
}
```

**Curl Example:**
```bash
curl -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePassword123!"
  }'
```

**Next Steps:**
After successful login, use the `access_token` in subsequent API requests:
```bash
curl -X GET "http://localhost:8000/chat/history" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

### 3. POST /auth/refresh

Refresh an expired access token using a valid refresh token.

**Request:**
```json
{
  "refresh_token": "refresh_token_opaque_string"
}
```

**Query Parameters:** None

**Request Headers:** None required

**Response (200 OK):**
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "new_refresh_token_opaque_string",
  "expires_in": 3600,
  "token_type": "Bearer"
}
```

**Validation Rules:**
- `refresh_token`: Must be valid refresh token from previous login/signup

**Possible Errors:**

| Status | Error Code | Description |
|--------|-----------|-------------|
| 401 | AUTH_INVALID_REFRESH_TOKEN | Token invalid or expired |
| 500 | AUTH_REFRESH_ERROR | Unexpected error |

**Example Error Response:**
```json
{
  "error": "Invalid refresh token",
  "detail": "The refresh token is invalid or has expired",
  "code": "AUTH_INVALID_REFRESH_TOKEN"
}
```

**Curl Example:**
```bash
curl -X POST "http://localhost:8000/auth/refresh" \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "refresh_token_from_previous_login"
  }'
```

**When to Use:**
- Access token is about to expire (check `expires_in`)
- Access token returned 401 Unauthorized
- Every 1 hour before token expiration (proactive)

---

### 4. POST /auth/logout

Logout current user (optional - primarily client-side operation).

**Request:**
```json
{}
```

**Query Parameters:** None

**Request Headers:**
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Successfully logged out"
}
```

**Possible Errors:**

| Status | Error Code | Description |
|--------|-----------|-------------|
| 401 | AUTH_001 | Missing or invalid token |
| 500 | AUTH_LOGOUT_ERROR | Unexpected error |

**Curl Example:**
```bash
curl -X POST "http://localhost:8000/auth/logout" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Best Practice:** Delete token on client-side immediately. Server-side logout is optional.

---

## Authentication Flow

### Registration → First Login
```
1. POST /auth/signup
   └─> Returns: access_token + refresh_token + user data

2. Store tokens in secure storage (localStorage, Keychain, etc)

3. Use access_token for authenticated requests
```

### Token Refresh Flow
```
1. Access token expires (after 3600 seconds)

2. POST /auth/refresh (with refresh_token)
   └─> Returns: new access_token

3. Resume using new access_token

4. If refresh token also expired → Return to login
```

### Complete Lifecycle
```
1. POST /auth/signup → get tokens
   ↓
2. Use access_token for API requests
   ↓
3. (After ~50 minutes) POST /auth/refresh → get new access_token
   ↓
4. Continue using new access_token
   ↓
5. User wants to logout → POST /auth/logout (optional)
   ↓
6. Delete tokens on client
   ↓
7. User must login again / return to signup
```

---

## JWT Token Structure

**Decoded Access Token Example:**
```json
{
  "sub": "uuid-12345678",
  "email": "user@example.com",
  "iat": 1705334400,
  "exp": 1705338000,
  "aud": "authenticated",
  "iss": "https://your-supabase-instance.supabase.co"
}
```

**Fields:**
- `sub`: User ID (Subject)
- `email`: User email
- `iat`: Issued at (timestamp)
- `exp`: Expiration time (timestamp)
- `aud`: Audience (always "authenticated")
- `iss`: Issuer (Supabase URL)

---

## Error Codes Reference

| Code | HTTP | Description |
|------|------|-------------|
| AUTH_EMAIL_EXISTS | 400 | Email already registered |
| AUTH_INVALID_CREDENTIALS | 401 | Wrong email or password |
| AUTH_PROFILE_NOT_FOUND | 404 | User profile missing |
| AUTH_INVALID_REFRESH_TOKEN | 401 | Refresh token invalid/expired |
| AUTH_001 | 401 | Missing/invalid access token |
| AUTH_CREATE_FAILED | 500 | Account creation failed |
| AUTH_SIGNUP_ERROR | 500 | Unexpected signup error |
| AUTH_LOGIN_ERROR | 500 | Unexpected login error |
| AUTH_REFRESH_ERROR | 500 | Unexpected refresh error |
| AUTH_LOGOUT_ERROR | 500 | Unexpected logout error |
| VAL_001 | 400 | Validation error (generic) |
| VAL_002 | 400 | Invalid parameter type |
| VAL_003 | 400 | Required field missing |

---

## Best Practices

### 1. Token Storage
```javascript
// ✅ GOOD: Secure storage
localStorage.setItem("access_token", token);  // HTTPOnly cookie better

// ❌ BAD: Global variable (vulnerable to XSS)
window.token = token;
```

### 2. Token Expiration
```javascript
// ✅ GOOD: Proactive refresh before expiration
setTimeout(() => refreshToken(), (expires_in - 300) * 1000);  // 5 min before

// ❌ BAD: Wait until token fails
if (response.status === 401) {
  refreshToken();  // Too late, user sees error
}
```

### 3. Error Handling
```javascript
// ✅ GOOD: Check error code
if (error.code === "AUTH_INVALID_REFRESH_TOKEN") {
  redirectToLogin();  // User must login again
}

// ❌ BAD: Generic error handling
if (error.status === 401) {
  // Might be rate limit, not auth failure
}
```

### 4. Password Security
- Minimum 8 characters (enforced by API)
- Avoid common patterns ("abc", "123", same as email)
- Never send password in logs
- Always use HTTPS in production

### 5. Token Usage
```javascript
// ✅ GOOD: Update Authorization header
fetch("/api/endpoint", {
  headers: {
    "Authorization": `Bearer ${access_token}`
  }
});

// ❌ BAD: Token in query parameter
fetch(`/api/endpoint?token=${access_token}`);  // Logged in server logs!
```

---

## Rate Limiting

**Per Email:** 100 requests/minute  
**Applies To:** signup, login, refresh (all auth endpoints)  
**Response Header:** `X-RateLimit-Remaining`  
**Error Response (429):**
```json
{
  "error": "Rate limit exceeded",
  "detail": "Too many authentication attempts",
  "code": "RATE_001",
  "retry_after_seconds": 60
}
```

---

## Session Management

**Token Validity:**
- Access Token: 1 hour (3600 seconds)
- Refresh Token: 7 days (auto-invalidates)
- Session Timeout: No server-side timeout (stateless JWT)

**Simultaneous Sessions:**
- Each login creates new tokens
- Previous tokens remain valid until expiration
- No forced logout of other sessions

**Logout Behavior:**
- Client deletes tokens (primary method)
- Server-side logout optional (invalidates session reference)
- Token remains valid until expiration if not deleted client-side

---

## Testing

### Signup Test
```bash
curl -X POST "http://localhost:8000/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123!",
    "display_name": "Test User"
  }'
```

### Login Test
```bash
curl -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPassword123!"
  }'
```

### Refresh Token Test
```bash
curl -X POST "http://localhost:8000/auth/refresh" \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "YOUR_REFRESH_TOKEN"
  }'
```

### Use Token in Request
```bash
curl -X GET "http://localhost:8000/chat/history" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## Changelog

### Version 1.0.0
- ✅ Signup endpoint with email validation
- ✅ Login endpoint with credential verification
- ✅ Token refresh endpoint
- ✅ Logout endpoint (optional)
- ✅ JWT token structure (HS256 signature)
- ✅ 29 validation and integration tests
- ✅ Error codes (13 codes defined)
- ✅ Rate limiting per email
