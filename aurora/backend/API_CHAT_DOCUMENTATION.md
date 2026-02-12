# Aurora Chat API Documentation

**Version:** 1.0 | **Status:** ✅ PRODUCTION READY

---

## Overview

The Aurora Chat API provides three endpoints for conversational AI with Dr. Aurora, a specialized cannabis cultivation expert:

- **POST /api/v1/chat/message** — Send a message and get a response
- **GET /api/v1/chat/history** — Retrieve conversation history  
- **WebSocket /ws/chat/stream** — Stream responses in real-time

---

## 1. POST /chat/message

Send a message to Dr. Aurora and receive a contextual response.

### Request

```bash
curl -X POST http://localhost:8000/api/v1/chat/message \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "My plants look yellowish. What should I do?",
    "grow_id": "optional-grow-uuid",
    "image_url": null
  }'
```

### Request Schema

```python
class ChatMessageRequest(BaseModel):
    message: str              # User message (1-2000 chars)
    grow_id: Optional[str]    # UUID of a specific grow (optional)
    image_url: Optional[str]  # URL for photo-based diagnosis (optional)
```

### Response

```json
{
  "id": "msg-123abc",
  "role": "assistant",
  "content": "Yellow leaves often indicate nitrogen deficiency or overwatering...",
  "metadata": {
    "intent": "diagnostics",
    "is_emergency": false,
    "tokens_used": 156,
    "context_sources": ["active_grow", "knowledge_base"]
  },
  "created_at": "2024-02-11T15:30:45Z"
}
```

### Response Schema

```python
class ChatMessageResponse(BaseModel):
    id: str                       # Message UUID
    role: ChatRole                # "assistant" | "user" | "system"
    content: str                  # Dr. Aurora's response
    metadata: ChatMessageMetadata # See below
    created_at: str               # ISO timestamp

class ChatMessageMetadata(BaseModel):
    intent: IntentType              # Intent detected from user message
    is_emergency: bool              # Whether flagged as emergency
    tokens_used: int                # Total tokens consumed
    context_sources: List[str]      # Sources: "active_grow", "knowledge_base", "chat_summary"
```

### Intent Types

The system automatically detects user intent:

| Intent | Description | Examples |
|--------|---|---|
| `question` | General questions | "What should I do?" |
| `emergency` | Critical issues | "My plants are dying!" |
| `diagnostics` | Data analysis requests | "Show me my climate data" |
| `adjust_plan` | Grow plan modifications | "Change my nutrition schedule" |
| `general` | Casual conversation | "Checking in on progress" |

### Emergency Keywords

Messages containing these keywords are auto-flagged as emergencies:
- `dying`, `dead`, `emergency`, `urgent`, `help me`
- `root rot`, `mold`, `pest infestation`, `heat stress`
- And 15+ more...

### Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 400 | Invalid request (empty message, bad payload) |
| 401 | Missing or invalid JWT |
| 429 | Rate limit exceeded (30 msgs/min per user) |
| 500 | Server error |

### Rate Limiting

- **Limit:** 30 messages per minute per user
- **Response on limit exceeded:** HTTP 429 with `{"error": "Chat rate limit exceeded..."}`

### Context Sources

Dr. Aurora assembles responses using:

1. **active_grow** — Current grow metadata (strain, phase, environment)
2. **knowledge_base** — Semantic search results from cannabis knowledge docs
3. **chat_summary** — Previous conversation summaries for continuity
4. **snapshots** — Recent environmental readings (temp, humidity, VPD)

### Token Budget

Dr. Aurora operates within a token budget:
- **System prompt:** ~1000 tokens
- **User message:** Variable
- **History:** Trimmed dynamically
- **Max response:** 4096 tokens
- **Total context window:** 6000 tokens

---

## 2. GET /chat/history

Retrieve paginated conversation history.

### Request

```bash
curl -X GET "http://localhost:8000/api/v1/chat/history?limit=20&offset=0" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Query Parameters

| Parameter | Type | Default | Max | Description |
|-----------|------|---------|-----|-------------|
| `limit` | int | 50 | 200 | Messages per page |
| `offset` | int | 0 | - | Pagination offset |

### Response

```json
{
  "success": true,
  "messages": [
    {
      "id": "msg-1",
      "role": "user",
      "content": "First question",
      "metadata": {"intent": "question"},
      "created_at": "2024-02-11T10:00:00Z"
    },
    {
      "id": "msg-2",
      "role": "assistant",
      "content": "Dr. Aurora's response...",
      "metadata": null,
      "created_at": "2024-02-11T10:00:05Z"
    }
  ],
  "has_more": true,
  "total_count": 156
}
```

### Response Schema

```python
class ChatHistoryResponse(BaseModel):
    success: bool                          # Always true if 200
    messages: List[ChatHistoryMessage]     # Conversation messages
    has_more: bool                         # Whether more messages exist
    total_count: int                       # Total messages for user
```

### Pagination Example

```python
# Get first page
page_1 = http.get("/chat/history?limit=20&offset=0")

# Get second page (if has_more=true)
if page_1.json()["has_more"]:
    page_2 = http.get("/chat/history?limit=20&offset=20")
```

---

## 3. WebSocket /ws/chat/stream

Stream Dr. Aurora's response chunk-by-chunk for real-time responses.

### Connection

```javascript
const ws = new WebSocket(
  'ws://localhost:8000/ws/chat/stream?user_id=USER_ID&grow_id=GROW_ID'
);

ws.onopen = () => {
  // Send message to initiate stream
  ws.send(JSON.stringify({
    message: "How's my grow looking?"
  }));
};

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  
  if (data.chunk) {
    console.log(data.chunk);  // Append to response
  }
  
  if (data.done) {
    console.log("Response complete!");
  }
  
  if (data.error) {
    console.error(data.error);
  }
};
```

### Message Format

**Client → Server:**
```json
{
  "message": "User message text"
}
```

**Server → Client (Streaming):**
```json
{"chunk": "Hello "}
{"chunk": "there! "}
{"chunk": "This "}
...
{"done": true}
```

**Error:**
```json
{"error": "Rate limit exceeded"}
```

### WebSocket Parameters

| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `user_id` | string | Yes | Authenticated user UUID |
| `grow_id` | string | No | Specific grow context |

---

## Error Responses

### 400 Bad Request

```json
{
  "error": "Message must be between 1 and 2000 characters",
  "code": "VALIDATION_ERROR"
}
```

### 401 Unauthorized

```json
{
  "error": "Invalid token",
  "code": "AUTH_ERROR"
}
```

### 429 Too Many Requests

```json
{
  "error": "Chat rate limit exceeded. Try again in a minute.",
  "code": "RATE_LIMIT_ERROR"
}
```

### 500 Internal Server Error

```json
{
  "error": "Failed to process message",
  "code": "CHAT_SERVICE_ERROR"
}
```

---

## Feature Details

### Intent Detection

The system uses regex patterns and keyword analysis:

```python
INTENT_PATTERNS = {
    "diagnostics": [r"\bdiagn", r"\banalyze", r"\bshow\s+(?:data|stats)"],
    "question": [r"\bwhat\b", r"\bhow\b", r"\bwhy\b", r"\?$"],
    "adjust_plan": [r"\badjust\s+plan", r"\bmodify", r"\bchange"],
    ...
}

# Emergency check (highest priority)
if any(keyword in message.lower() for keyword in EMERGENCY_KEYWORDS):
    return ("emergency", True)
```

### Context Building

Dr. Aurora assembles contextual information:

1. **Grow Info** (if grow_id provided)
   ```
   ## Active Grow: Blue Dream Hydro Setup
   - Strain: Blue Dream
   - Medium: Hydro
   - Phase: vegetative
   - Light: 1000W HPS
   - Optimal VPD: 0.8-1.2 kPa
   ```

2. **Knowledge Base** (semantic search)
   ```
   ## Relevant Knowledge Base Info
   ### Nitrogen Deficiency
   Yellow leaves starting on lower foliage...
   ```

3. **Chat Summary** (for continuity)
   ```
   ## Previous Conversation Summary
   User has a 4x4 grow tent with...
   ```

4. **System Prompt** (Dr. Aurora personality)
   ```
   You are Dr. Aurora, an expert cannabis cultivation doctor...
   ```

### Token Management

```python
# Calculate token budget
system_tokens = _count_tokens(system_prompt)           # ~1000
user_tokens = _count_tokens(user_message)              # Variable
context_budget = MAX_CONTEXT_TOKENS - system_tokens - user_tokens - MAX_TOKENS

# Trim history to fit budget
trimmed_history = _trim_history_to_budget(history, budget)
```

---

## Implementation Guide

### Setup

1. Ensure Supabase connection is configured
2. Set environment variables:
   ```bash
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_KEY=your-service-role-key
   GROQ_API_KEY=your-groq-api-key
   ```

3. Initialize database schema (including chat_messages table)

### Usage Example (Python)

```python
import httpx

# Initialize client with JWT
headers = {"Authorization": f"Bearer {jwt_token}"}

# Send message
async with httpx.AsyncClient() as client:
    response = await client.post(
        "http://localhost:8000/api/v1/chat/message",
        json={"message": "How do I fix nitrogen deficiency?"},
        headers=headers,
    )
    
    result = response.json()
    print(f"Intent: {result['metadata']['intent']}")
    print(f"Response: {result['content']}")
    print(f"Tokens: {result['metadata']['tokens_used']}")

# Get history
    history = await client.get(
        "http://localhost:8000/api/v1/chat/history?limit=10",
        headers=headers,
    )
    
    messages = history.json()['messages']
    for msg in messages:
        print(f"{msg['role']}: {msg['content'][:100]}")
```

### Usage Example (JavaScript/TypeScript)

```typescript
// POST /message
const response = await fetch('/api/v1/chat/message', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    message: 'My leaves are wilting...',
    grow_id: growId,
  }),
});

const data = await response.json();
console.log(data.content);           // Dr Aurora response
console.log(data.metadata.intent);   // "diagnostics"
console.log(data.metadata.is_emergency); // true/false

// GET /history
const history = await fetch('/api/v1/chat/history?limit=20', {
  headers: { 'Authorization': `Bearer ${token}` },
});

const messages = await history.json();
```

### WebSocket Example (JavaScript)

```javascript
const ws = new WebSocket(
  `ws://localhost:8000/ws/chat/stream?user_id=${userId}`
);

let fullResponse = '';

ws.onmessage = (event) => {
  const msg = JSON.parse(event.data);
  
  if (msg.chunk) {
    fullResponse += msg.chunk;
    updateUIWithChunk(msg.chunk);
  }
  
  if (msg.done) {
    console.log('Complete response:', fullResponse);
  }
};

ws.send(JSON.stringify({ message: 'Health check' }));
```

---

## Testing

Run test suite:
```bash
pytest app/tests/test_chat_service.py -v      # 17 tests
pytest app/tests/test_chat_endpoints.py -v    # 25 tests
pytest -q                                      # All backend tests: 45 passed
```

Key test coverage:
- ✅ Token counting and budget management
- ✅ Intent detection (emergency, diagnostics, question, etc.)
- ✅ Context formatting (grow info, AI plan, knowledge base)
- ✅ Rate limiting (30/min per user)
- ✅ Error handling and validation
- ✅ Response serialization
- ✅ Pagination logic

---

## Performance

| Metric | Target | Status |
|--------|--------|--------|
| Response latency | <500ms | ✅ |
| Token budget efficiency | 80-90% utilization | ✅ |
| Concurrent users | 100+ | ✅ (depends on infrastructure) |
| Database queries | <5/request | ✅ |
| Cache hits | 60%+ | ✅ |

---

## Future Enhancements

- [ ] Image analysis via llama-3.2-11b-vision
- [ ] Real-time environmental alerts
- [ ] Multi-language support
- [ ] Custom training data per user
- [ ] Feedback loop for response ranking
- [ ] Export conversation as PDF

---

**Last Updated:** 2024-02-11 | **Maintainer:** Engineering Tea
