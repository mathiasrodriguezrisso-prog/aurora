"""
📁 backend/app/routers/auth.py
Authentication Endpoints — signup, login, token refresh
"""

import logging
from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field, EmailStr
from supabase import Client

from app.dependencies import get_supabase_client, get_current_user_id

logger = logging.getLogger("aurora.auth")

router = APIRouter(prefix="/auth", tags=["Authentication"])

# ── Pydantic Models ─────────────────────────────────────────────

class SignupRequest(BaseModel):
    email: EmailStr = Field(..., description="User email address")
    password: str = Field(..., min_length=8, max_length=128, description="Password (8+ chars)")
    display_name: str = Field(..., min_length=1, max_length=50, description="Display name")
    role: Optional[str] = Field(default="grower", description="User role: grower, breeder, etc")

class SignupResponse(BaseModel):
    id: str
    email: str
    display_name: str
    role: str
    created_at: str
    access_token: str
    refresh_token: Optional[str] = None
    expires_in: int  # seconds
    token_type: str = "Bearer"

class LoginRequest(BaseModel):
    email: EmailStr = Field(..., description="User email address")
    password: str = Field(..., description="User password")

class LoginResponse(BaseModel):
    id: str
    email: str
    display_name: str
    role: str
    access_token: str
    refresh_token: Optional[str] = None
    expires_in: int  # seconds
    token_type: str = "Bearer"

class RefreshTokenRequest(BaseModel):
    refresh_token: str = Field(..., description="Refresh token from login/signup")

class RefreshTokenResponse(BaseModel):
    access_token: str
    refresh_token: Optional[str] = None
    expires_in: int  # seconds
    token_type: str = "Bearer"

class LogoutRequest(BaseModel):
    pass  # Optional body

class ErrorResponse(BaseModel):
    error: str
    detail: str
    code: str


# ── Signup Endpoint ─────────────────────────────────────────────

@router.post(
    "/signup",
    response_model=SignupResponse,
    status_code=status.HTTP_201_CREATED,
)
async def signup(
    request: SignupRequest,
):
    """
    Register a new user.
    
    - Email must be unique
    - Password must be at least 8 characters
    - Display name is required (1-50 chars)
    - Role defaults to 'grower'
    """
    sb = get_supabase_client()
    
    try:
        # Check if email already exists
        existing = await _check_email_exists(sb, request.email)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    "error": "Email already registered",
                    "detail": f"The email {request.email} is already associated with an account",
                    "code": "AUTH_EMAIL_EXISTS"
                }
            )
        
        # Create user via Supabase Auth
        auth_response = await _create_auth_user(sb, request.email, request.password)
        
        if not auth_response.get("user"):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail={
                    "error": "Failed to create user account",
                    "detail": "Please try again later",
                    "code": "AUTH_CREATE_FAILED"
                }
            )
        
        user_id = auth_response["user"]["id"]
        access_token = auth_response.get("session", {}).get("access_token")
        refresh_token = auth_response.get("session", {}).get("refresh_token")
        expires_in = auth_response.get("session", {}).get("expires_in", 3600)
        
        # Create user profile
        profile = await _create_user_profile(
            sb,
            user_id,
            request.email,
            request.display_name,
            request.role
        )
        
        return SignupResponse(
            id=user_id,
            email=request.email,
            display_name=request.display_name,
            role=request.role,
            created_at=profile.get("created_at", datetime.utcnow().isoformat()),
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=expires_in
        )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Signup error: %s", e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": "Registration failed",
                "detail": "An unexpected error occurred. Please try again later.",
                "code": "AUTH_SIGNUP_ERROR"
            }
        )


# ── Login Endpoint ──────────────────────────────────────────────

@router.post(
    "/login",
    response_model=LoginResponse,
    status_code=status.HTTP_200_OK,
)
async def login(
    request: LoginRequest,
):
    """
    Login with email and password.
    
    Returns JWT access token and optional refresh token.
    """
    sb = get_supabase_client()
    
    try:
        # Authenticate via Supabase
        auth_response = await _authenticate_user(sb, request.email, request.password)
        
        if not auth_response.get("user"):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail={
                    "error": "Invalid credentials",
                    "detail": "Email or password is incorrect",
                    "code": "AUTH_INVALID_CREDENTIALS"
                }
            )
        
        user_id = auth_response["user"]["id"]
        access_token = auth_response.get("session", {}).get("access_token")
        refresh_token = auth_response.get("session", {}).get("refresh_token")
        expires_in = auth_response.get("session", {}).get("expires_in", 3600)
        
        # Get user profile
        profile = await _get_user_profile(sb, user_id)
        
        if not profile:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={
                    "error": "User profile not found",
                    "detail": "User account exists but profile data is missing",
                    "code": "AUTH_PROFILE_NOT_FOUND"
                }
            )
        
        return LoginResponse(
            id=user_id,
            email=request.email,
            display_name=profile.get("display_name", "User"),
            role=profile.get("role", "grower"),
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=expires_in
        )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Login error: %s", e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": "Login failed",
                "detail": "An unexpected error occurred. Please try again later.",
                "code": "AUTH_LOGIN_ERROR"
            }
        )


# ── Refresh Token Endpoint ──────────────────────────────────────

@router.post(
    "/refresh",
    response_model=RefreshTokenResponse,
    status_code=status.HTTP_200_OK,
)
async def refresh_token(
    request: RefreshTokenRequest,
):
    """
    Refresh an expired access token using a refresh token.
    
    Returns new access token and optional new refresh token.
    """
    sb = get_supabase_client()
    
    try:
        # Refresh session via Supabase
        refresh_response = await _refresh_session(sb, request.refresh_token)
        
        if not refresh_response.get("session"):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail={
                    "error": "Invalid refresh token",
                    "detail": "The refresh token is invalid or has expired",
                    "code": "AUTH_INVALID_REFRESH_TOKEN"
                }
            )
        
        session = refresh_response["session"]
        access_token = session.get("access_token")
        new_refresh_token = session.get("refresh_token")
        expires_in = session.get("expires_in", 3600)
        
        return RefreshTokenResponse(
            access_token=access_token,
            refresh_token=new_refresh_token,
            expires_in=expires_in
        )
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error("Refresh token error: %s", e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": "Token refresh failed",
                "detail": "An unexpected error occurred. Please login again.",
                "code": "AUTH_REFRESH_ERROR"
            }
        )


# ── Logout Endpoint (Optional) ──────────────────────────────────

@router.post(
    "/logout",
    status_code=status.HTTP_200_OK,
)
async def logout(
    user_id: str = Depends(get_current_user_id),
):
    """
    Logout the current user.
    
    Invalidates the current session (optional - client-side token deletion is primary method).
    """
    sb = get_supabase_client()
    
    try:
        # Sign out user session (optional)
        await _logout_user(sb, user_id)
        
        return {
            "success": True,
            "message": "Successfully logged out"
        }
    
    except Exception as e:
        logger.error("Logout error: %s", e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": "Logout failed",
                "detail": "An unexpected error occurred",
                "code": "AUTH_LOGOUT_ERROR"
            }
        )


# ── Helper Functions ────────────────────────────────────────────

async def _check_email_exists(sb: Client, email: str) -> bool:
    """Check if email already exists in the system."""
    try:
        result = await _exec(
            sb.table("profiles")
            .select("id")
            .eq("email", email)
            .limit(1)
            .execute
        )
        return len(result.data) > 0
    except Exception as e:
        logger.error("Email check error: %s", e)
        return False


async def _create_auth_user(sb: Client, email: str, password: str) -> dict:
    """Create a user via Supabase Auth."""
    try:
        # This would use the Supabase Python SDK auth method
        # For now, return a mock response structure
        result = await _exec(
            sb.auth.sign_up({
                "email": email,
                "password": password
            })
        )
        return result
    except Exception as e:
        logger.error("Auth user creation error: %s", e)
        raise


async def _authenticate_user(sb: Client, email: str, password: str) -> dict:
    """Authenticate user via Supabase Auth."""
    try:
        result = await _exec(
            sb.auth.sign_in_with_password({
                "email": email,
                "password": password
            })
        )
        return result
    except Exception as e:
        logger.error("Authentication error: %s", e)
        raise


async def _refresh_session(sb: Client, refresh_token: str) -> dict:
    """Refresh authentication session."""
    try:
        result = await _exec(
            sb.auth.refresh_session(refresh_token)
        )
        return result
    except Exception as e:
        logger.error("Session refresh error: %s", e)
        raise


async def _logout_user(sb: Client, user_id: str) -> None:
    """Logout user (invalidate session)."""
    try:
        await _exec(sb.auth.sign_out())
    except Exception as e:
        logger.error("Logout error: %s", e)
        # Don't raise - logout failure shouldn't block the endpoint


async def _create_user_profile(
    sb: Client,
    user_id: str,
    email: str,
    display_name: str,
    role: str
) -> dict:
    """Create user profile in database."""
    try:
        result = await _exec(
            sb.table("profiles")
            .insert({
                "id": user_id,
                "email": email,
                "display_name": display_name,
                "role": role,
                "avatar_url": None,
                "bio": None,
                "total_xp": 0,
                "karma_score": 0,
                "reputation": 0,
                "created_at": datetime.utcnow().isoformat(),
                "updated_at": datetime.utcnow().isoformat()
            })
            .execute
        )
        return result.data[0] if result.data else {}
    except Exception as e:
        logger.error("Profile creation error: %s", e)
        raise


async def _get_user_profile(sb: Client, user_id: str) -> Optional[dict]:
    """Get user profile from database."""
    try:
        result = await _exec(
            sb.table("profiles")
            .select("*")
            .eq("id", user_id)
            .limit(1)
            .execute
        )
        return result.data[0] if result.data else None
    except Exception as e:
        logger.error("Profile fetch error: %s", e)
        return None


async def _exec(func):
    """Execute async Supabase operation."""
    import asyncio
    return await asyncio.to_thread(func)
