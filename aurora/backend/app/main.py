"""
📁 backend/app/main.py
Aurora Backend — FastAPI Application Entry Point.

Registers all routers, configures CORS, logging middleware,
global exception handling, and startup health checks.
"""

import logging
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.socket_manager import socket_manager

from app.config import settings
from app.dependencies import get_supabase_client, get_groq_client, verify_jwt
from app.routers import health, grow, chat, social

# ── Logging ─────────────────────────────────────────────────────

logging.basicConfig(
    level=logging.DEBUG if settings.debug else logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("aurora")


# ── Lifespan (startup / shutdown) ───────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler — verify external services on startup."""
    logger.info("🌱 Aurora Backend starting...")
    logger.info("📍 Environment: %s", settings.environment)

    # Check for JWT secret
    if not settings.supabase_jwt_secret:
        logger.critical("❌ SUPABASE_JWT_SECRET is not set! Authentication will fail.")
    else:
        logger.info("✅ SUPABASE_JWT_SECRET is configured")

    # Start scheduler
    try:
        from app.core.scheduler import start_scheduler
        start_scheduler()
        logger.info("✅ Scheduler started")
    except Exception as e:
        logger.warning("⚠️  Scheduler start failed: %s", e)

    # Verify Supabase connection
    try:
        sb = get_supabase_client()
        sb.table("profiles").select("id").limit(1).execute()
        logger.info("✅ Supabase connection verified")
    except Exception as e:
        logger.warning("⚠️  Supabase health check failed: %s", e)

    # Verify Groq connection
    try:
        groq = get_groq_client()
        groq.models.list()
        logger.info("✅ Groq connection verified")
    except Exception as e:
        logger.warning("⚠️  Groq health check failed: %s", e)

    yield

    # Stop scheduler
    try:
        from app.core.scheduler import stop_scheduler
        stop_scheduler()
    except Exception:
        pass

    logger.info("🌙 Aurora Backend shutting down...")


# ── App Creation ────────────────────────────────────────────────

app = FastAPI(
    title="Aurora API",
    description="Backend API for Aurora Cannabis Cultivation App",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
)


# ── CORS ────────────────────────────────────────────────────────

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ── Request Logging Middleware ──────────────────────────────────

@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log every request with method, path, and elapsed time."""
    start = time.perf_counter()
    response = await call_next(request)
    elapsed_ms = (time.perf_counter() - start) * 1000
    logger.info(
        "%s %s → %s (%.1fms)",
        request.method,
        request.url.path,
        response.status_code,
        elapsed_ms,
    )
    return response


# ── Debug Middleware for generate-plan (Temporary) ────────────────

@app.middleware("http")
async def log_generate_plan_requests(request: Request, call_next):
    """Log the raw body of generate-plan requests to debug 422 errors."""
    if request.method == "POST" and "generate-plan" in str(request.url):
        body_bytes = await request.body()
        logger.info(f"📥 POST generate-plan BODY: {body_bytes.decode('utf-8', errors='replace')}")
        
        # Re-create the request body so it can be read again by the endpoint
        async def receive():
            return {"type": "http.request", "body": body_bytes}
        request._receive = receive
    
    response = await call_next(request)
    return response


# ── Global Exception Handler ───────────────────────────────────

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Catch-all for unhandled exceptions so the client always gets JSON."""
    logger.exception("Unhandled error on %s %s", request.method, request.url.path)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "detail": {
                "error": "Internal server error. Please try again later."
            }
        },
    )


# ── Register Routers ───────────────────────────────────────────

# Core routers (already exist)
app.include_router(health.router, tags=["Health"])
app.include_router(grow.router)
app.include_router(chat.router)
app.include_router(social.router)

# New routers — imported lazily so the app still starts if files
# don't exist yet (during incremental development).
try:
    from app.routers import social
    app.include_router(social.router)
    logger.info("✅ Social router loaded")
except ImportError:
    logger.info("⏳ Social router not yet available")

try:
    from app.routers import users
    app.include_router(users.router)
    logger.info("✅ Users router loaded")
except ImportError:
    logger.info("⏳ Users router not yet available")

try:
    from app.routers import tasks
    app.include_router(tasks.router)
    logger.info("✅ Tasks router loaded")
except ImportError:
    logger.info("⏳ Tasks router not yet available")

try:
    from app.routers import sensors
    app.include_router(sensors.router)
    logger.info("✅ Sensors router loaded")
except ImportError:
    logger.info("⏳ Sensors router not yet available")

try:
    from app.routers import media
    app.include_router(media.router)
    logger.info("✅ Media router loaded")
except ImportError:
    logger.info("⏳ Media router not yet available")



# ── Root Endpoint ───────────────────────────────────────────────

@app.get("/")
async def root():
    """Root endpoint — basic health info."""
    return {
        "app": "Aurora API",
        "version": "1.0.0",
        "environment": settings.environment,
        "status": "running",
    }


@app.get("/api/v1/auth/test-token")
async def test_token(request: Request):
    """Endpoint temporal para debuggear JWT"""
    auth_header = request.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        return {"error": "No Bearer token found", "header": auth_header[:50]}
    
    token = auth_header.split(" ")[1]
    
    # Decodificar SIN verificar para ver el contenido
    from jose import jwt as jose_jwt
    try:
        # Decodificar sin verificar firma (solo para debug)
        # python-jose uses get_unverified_claims/header or similar, but decode with verify=False works too usually
        # but let's use the user's snippet logic or similar adaptation for python-jose
        unverified = jose_jwt.get_unverified_claims(token)
        header = jose_jwt.get_unverified_header(token)
        return {
            "status": "token_decoded_without_verification",
            "alg": header.get("alg"),
            "sub": unverified.get("sub"),
            "email": unverified.get("email"),
            "role": unverified.get("role"),
            "aud": unverified.get("aud"),
            "exp": unverified.get("exp"),
            "iss": unverified.get("iss"),
        }
    except Exception as e:
        return {"error": str(e), "token_preview": token[:50] + "..."}


@app.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    """
    WebSocket endpoint for real-time notifications and updates.
    """
    await socket_manager.connect(websocket, user_id)
    try:
        while True:
            # Keep connection alive
            await websocket.receive_text()
    except WebSocketDisconnect:
        socket_manager.disconnect(websocket, user_id)
    except Exception as e:
        logger.error(f"WebSocket error for user {user_id}: {e}")
        socket_manager.disconnect(websocket, user_id)
