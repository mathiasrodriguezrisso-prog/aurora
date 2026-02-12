"""
Aurora Backend - Dependency Injection
Provides cached clients and authentication helpers for FastAPI.
"""
import logging
from functools import lru_cache
from typing import Dict, Any

import httpx
from fastapi import Depends, HTTPException, status, Request
from jose import JWTError, jwt, jwk
from supabase import create_client, Client
from groq import Groq, AsyncGroq

from app.config import settings

logger = logging.getLogger(__name__)


@lru_cache()
def get_supabase_client() -> Client:
    """Get cached Supabase client instance."""
    return create_client(
        settings.supabase_url,
        settings.supabase_service_role_key,
    )


@lru_cache()
def get_groq_client() -> Groq:
    """Get cached Groq client instance."""
    return Groq(api_key=settings.groq_api_key)


@lru_cache()
def get_async_groq_client() -> AsyncGroq:
    """Get cached AsyncGroq client instance."""
    return AsyncGroq(api_key=settings.groq_api_key)


# --- FastAPI dependency helpers ---


def get_supabase() -> Client:
    """FastAPI dependency for Supabase client."""
    return get_supabase_client()


def get_groq() -> Groq:
    """FastAPI dependency for Groq client."""
    return get_groq_client()


def get_async_groq() -> AsyncGroq:
    """FastAPI dependency for AsyncGroq client."""
    return get_async_groq_client()




# In-memory cache for JWKS
_JWKS_CACHE: Dict[str, Any] = {}


async def get_supabase_jwks() -> dict:
    """
    Fetch Supabase JWKS (JSON Web Key Set) for verifying RS256/ES256 tokens.
    Uses simple in-memory caching.
    """
    if _JWKS_CACHE.get("keys"):
        return _JWKS_CACHE["keys"]

    jwks_url = f"{settings.supabase_url}/auth/v1/.well-known/jwks.json"
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(jwks_url, timeout=10.0)
            response.raise_for_status()
            jwks = response.json()
            _JWKS_CACHE["keys"] = jwks
            return jwks
    except Exception as e:
        logger.error(f"Failed to fetch JWKS from {jwks_url}: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service unavailable",
        )


async def verify_jwt(token: str) -> dict:
    """
    Verify the Supabase JWT token.
    Supports both HS256 (Shared Secret) and RS256/ES256 (JWKS).
    
    Args:
        token: The raw JWT token string.
        
    Returns:
        dict: The decoded payload.
        
    Raises:
        HTTPException: If token is invalid, expired, or verification fails.
    """
    try:
        # 1. Check header for algorithm
        header = jwt.get_unverified_header(token)
        alg = header.get("alg")
        
        if not alg:
            raise JWTError("Missing algorithm in token header")

        # 2. Verify based on algorithm
        if alg == "HS256":
            # Verify using Shared Secret
            payload = jwt.decode(
                token,
                settings.supabase_jwt_secret,
                algorithms=["HS256"],
                audience="authenticated",
                options={"verify_aud": True},
            )
            return payload
            
        elif alg in ["RS256", "ES256"]:
            # Verify using Public Key (JWKS)
            jwks = await get_supabase_jwks()
            kid = header.get("kid")
            if not kid:
                raise JWTError("Missing 'kid' in token header for asymmetric key")

            # Find matching key
            key_data = next((k for k in jwks.get("keys", []) if k.get("kid") == kid), None)
            if not key_data:
                # Force refresh cache once if key not found
                _JWKS_CACHE.clear()
                jwks = await get_supabase_jwks()
                key_data = next((k for k in jwks.get("keys", []) if k.get("kid") == kid), None)
                
            if not key_data:
                raise JWTError(f"Public key not found for kid: {kid}")

            # python-jose construct key
            public_key = jwk.construct(key_data)
            
            payload = jwt.decode(
                token,
                public_key,
                algorithms=[alg],
                audience="authenticated",
                options={"verify_aud": True},
            )
            return payload
        else:
            raise JWTError(f"Unsupported algorithm: {alg}")

    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expired",
        )
    except JWTError as e:
        logger.warning(f"JWT verification failed ({alg}): {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}",
        )


async def get_current_user_id(request: Request) -> str:
    """
    Extract and verify the authenticated user ID from the
    Supabase JWT in the Authorization header.
    """
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or malformed Authorization header",
        )

    token = auth_header.split(" ", 1)[1]
    payload = await verify_jwt(token)
    
    user_id: str | None = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token missing 'sub' claim",
        )
    return user_id
