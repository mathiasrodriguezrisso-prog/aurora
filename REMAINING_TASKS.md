# 📋 Aurora MVP - Remaining Tasks

**Status:** 🔄 IN PROGRESS | **Version:** v0.1 Beta

---

## Phase 6: API Implementation (Ready to Start)

### Task 1: Chat Endpoint - Dr. Aurora
**Priority:** ⭐⭐⭐⭐⭐ (Core AI Feature)

```python
# POST /chat/message
{
  "user_id": "uuid",
  "message": "Mi planta está amarillenta...",
  "context": {
    "grow_id": "uuid",
    "veg_stage": "seedling"
  }
}

# Response:
{
  "message_id": "uuid",
  "response": "Based on VAI (Vapor Axis Intelligence)...",
  "confidence": 0.92,
  "sources": ["knowledge_docs[id_1]", "knowledge_docs[id_2]"],
  "recommendations": [
    {"action": "increase_nitrogen", "severity": "high"},
    {"action": "check_humidity", "severity": "medium"}
  ]
}
```

**Implementation:**
- [ ] Create endpoint in `routers/chat.py`
- [ ] Implement `services/chat.py` with context assembly
- [ ] Call `app.core.groq_manager.call_groq_json()` with system prompt
- [ ] Use `services/rag.py` for `match_knowledge_docs()` via Supabase RPC
- [ ] Add prompt engineering for Dr. Aurora personality

**Tests Needed:**
- [ ] POST /chat/message with valid input
- [ ] Token counting (budget 2000 tokens default)
- [ ] Semantic search returns correct docs
- [ ] Response format validation

---

### Task 2: Social Feed Endpoint
**Priority:** ⭐⭐⭐⭐

```python
# POST /feed/post
{
  "user_id": "uuid",
  "grow_id": "uuid",
  "content": "Day 21 flowering! Looking good...",
  "images": ["url1", "url2"],
  "tags": ["flowering", "hydro", "llm"]
}

# GET /feed?limit=20&offset=0
# Response: Array of posts with engagement metrics
```

**Implementation:**
- [ ] Create endpoints in `routers/social.py`
- [ ] Implement `services/feed.py` with vector search
- [ ] Use RPC `match_posts()` for semantic recommendations
- [ ] Include engagement metrics (likes, comments, shares)

**Tests Needed:**
- [ ] POST creates post with correct timestamps
- [ ] GET /feed returns posts ordered by relevance
- [ ] Comments increment correctly (RPC)

---

### Task 3: VPD Climate Endpoint
**Priority:** ⭐⭐⭐

```python
# GET /climate/vpd?temp=25&humidity=65&pressure=101.325
{
  "temperature_c": 25,
  "humidity_rh": 65,
  "vpd_kpa": 1.82,
  "saturation_vapor_pressure": 3.167,
  "actual_vapor_pressure": 2.06,
  "status": "optimal",
  "recommendation": "Conditions ideal for vegetative growth"
}
```

**Implementation:**
- [ ] Create endpoint in `routers/grow.py`
- [ ] Use `utils/vpd.py` functions
- [ ] Add growth stage mapping for recommendations
- [ ] Cache results (Redis or simple dict)

**Tests Needed:**
- [ ] Known values match Tetens formula
- [ ] Edge cases (100% RH, 0% RH)
- [ ] Response format validation

---

### Task 4: Authentication Endpoints
**Priority:** ⭐⭐⭐⭐⭐

```python
# POST /auth/signup
{
  "email": "grower@example.com",
  "password": "secure123",
  "username": "CannabisChef"
}

# POST /auth/login
{
  "email": "grower@example.com",
  "password": "secure123"
}

# Response:
{
  "access_token": "eyJhbGciOiJIUzI1NiI...",
  "user": {"id": "uuid", "email": "...", "username": "..."},
  "expires_in": 3600
}
```

**Implementation:**
- [ ] Create endpoint in `routers/auth.py` (new)
- [ ] Integrate Supabase JWT (app.services.supabase_client)
- [ ] Hash passwords (Supabase handles this)
- [ ] Add refresh token logic

**Tests Needed:**
- [ ] Signup creates user in profiles table
- [ ] Login returns valid JWT
- [ ] JWT can authenticate other endpoints (middleware)
- [ ] Invalid credentials return 401

---

## Phase 7: Frontend Integration

### Task 5: Connect Flutter to Backend
**Priority:** ⭐⭐⭐⭐

```dart
// lib/core/api/client.dart
class AuroraApiClient {
  static const String baseUrl = 'http://localhost:8000/api/v1';
  
  Future<ChatResponse> sendChatMessage(String message) async {
    // POST /chat/message
  }
  
  Future<List<Post>> getFeed({int limit = 20}) async {
    // GET /feed
  }
}

// lib/features/chat/chat_screen.dart
// Connect ChatDrAuroraScreen to API client
```

**Implementation:**
- [ ] Create `http` dependency in pubspec.yaml
- [ ] Build API client in `lib/core/api/`
- [ ] Connect each screen to corresponding endpoint
- [ ] Add loading/error states
- [ ] Add JWT token handling

**Tests Needed:**
- [ ] API calls work from Flutter emulator/device
- [ ] Token refresh on 401 responses
- [ ] Error messages display correctly

---

### Task 6: Real-time Chat UI
**Priority:** ⭐⭐

```dart
// lib/features/chat/widgets/message_bubble.dart
// - Implement message animation
// - Add typing indicator
// - Show source citations

// lib/features/chat/chat_screen.dart
// - Message input field
// - Scroll to latest
// - Dr. Aurora branding
```

**Implementation:**
- [ ] Create message widgets
- [ ] Implement stream-based chat (optional: WebSocket)
- [ ] Add glassmorphism effects
- [ ] Smooth animations

---

## Phase 8: Advanced Features

### Task 7: Vector Search Enhancement
**Priority:** ⭐⭐⭐

**Current State:** Basic pgvector with IVFFlat index (nlist=100)

**Improvements:**
- [ ] Add hybrid search (keyword + semantic)
- [ ] Implement chunk re-ranking with Groq
- [ ] Add citation formatting in responses
- [ ] Track search quality metrics

---

### Task 8: Antigravity System
**Priority:** ⭐⭐

This is the **Feedback Loop AI Engine**:

**Architect Motor:** (Decision Making)
- [ ] Analyze all posts/chats for recurring issues
- [ ] Generate "Growth Protocols" recommendations
- [ ] Track effectiveness metrics

**Curator Motor:** (Content Selection)
- [ ] Rank knowledge_docs by usage
- [ ] Deprecate low-relevance docs
- [ ] Add seasonal content

**Outcome:** Self-improving knowledge base

**Implementation:**
- [ ] Create `services/antigravity.py`
- [ ] Scheduled job (daily) to analyze conversations
- [ ] RPC function to update doc relevance scores
- [ ] Dashboard view of recommendations

---

## Phase 9: Testing & QA

### Task 9: E2E Tests
**Priority:** ⭐⭐⭐

```python
# tests/e2e/test_chat_flow.py
def test_user_submits_chlorosis_question():
    # 1. Login as user
    # 2. Submit chat message about yellowing
    # 3. Verify Dr. Aurora responds with nitrogen recommendations
    # 4. Verify sources from knowledge_base
    # 5. Verify response in /feed
```

**Tools:**
- [ ] pytest (backend)
- [ ] integration_test plugin (Flutter)

---

### Task 10: Performance Testing
**Priority:** ⭐⭐

- [ ] Load test: 100 concurrent users → `/feed` should respond in <500ms
- [ ] Vector search latency: pgvector + IVFFlat should index 10k docs in <2s
- [ ] Token budget: Dr. Aurora responses should stay <2000 tokens

**Tools:**
- [ ] locust (load testing)
- [ ] pytest-benchmark (backend)

---

## Phase 10: Production Deployment

### Task 11: Cloud Deployment
**Priority:** ⭐

**Options:**
1. **Google Cloud Run** (serverless)
   - [ ] Push Docker image to GCR
   - [ ] Deploy with `gcloud run deploy`
   - [ ] Set env vars (SUPABASE_URL, GROQ_API_KEY)

2. **Docker Compose** (local or VPS)
   - [ ] Add `docker-compose.yml` for backend + database
   - [ ] Add PostgreSQL image with pgvector pre-installed

3. **Kubernetes** (advanced)
   - [ ] Create Helm charts for backend
   - [ ] Set up ingress + SSL
   - [ ] Auto-scaling based on CPU

---

## 📊 Prioritization Matrix

| Phase | Task | Priority | Effort | Blockers |
|-------|------|----------|--------|----------|
| 6 | Chat Endpoint | ⭐⭐⭐⭐⭐ | High | None (ready) |
| 6 | Feed Endpoint | ⭐⭐⭐⭐ | Medium | Supabase schema ✅ |
| 6 | VPD Endpoint | ⭐⭐⭐ | Low | vpd.py ✅ |
| 6 | Auth Endpoints | ⭐⭐⭐⭐⭐ | High | None (ready) |
| 7 | Flutter Integration | ⭐⭐⭐⭐ | Medium | API endpoints ready |
| 8 | Advanced Features | ⭐⭐ | High | Endpoints working |
| 9 | Testing | ⭐⭐⭐ | Medium | Code ready |
| 10 | Production Deploy | ⭐⭐ | Medium | Everything else done |

---

## 🔄 Recommended Execution Order

**Week 1:**
1. ✅ **Done:** Backend scaffold + DB schema
2. **Next:** Task 1-4 (Auth + Chat + Feed + VPD endpoints)
3. Run `pytest` for each endpoint

**Week 2:**
```bash
# After endpoints are ready:
pytest -v aurora/backend/app/tests/
# Should have 50+ passing tests
```

4. Task 5 (Flutter integration)
5. Task 6 (UI polish)

**Week 3:**
6. Task 7-8 (Advanced features)
7. Task 9-10 (Testing + deployment)

---

## 💾 Local Development Checklist

```bash
# Before starting any task:
[ ] cd aurora/backend
[ ] source .venv/Scripts/activate  # or venv\Scripts\activate on Windows
[ ] pip install -r requirements-dev.txt
[ ] pytest -q  # Verify tests pass
[ ] export SUPABASE_URL=... SUPABASE_KEY=... GROQ_API_KEY=...
[ ] uvicorn app.main:app --reload

# After each task:
[ ] Write tests
[ ] Run: pytest -q
[ ] Run: git add . && git commit -m "Task X: ..."
[ ] Push: git push origin main
[ ] Check GitHub Actions ✅
```

---

## 🆘 Help Needed

**Questions for User:**

1. **Frontend Priority:** Flutter web first, or mobile (iOS/Android)?
2. **Vector DB:** Keep pgvector, or add Pinecone for scale?
3. **LLM Upgrade:** Stay with llama-3.1-8b, or upgrade to llama-3.2-11b-vision (for image analysis)?
4. **Real-time:** WebSocket for live chat, or polling for MVP?
5. **Auth Method:** Supabase JWT only, or add Google/Discord OAuth?

---

**Status:** Ready to begin Phase 6 ✅ | **Next Review:** After Task 1-4 completion
