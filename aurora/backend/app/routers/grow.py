"""
Aurora Grow Router
API endpoints for grow plan generation and management.
"""
import asyncio
import logging
from datetime import timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status, Request
from supabase import Client
from groq import Groq
from cachetools import TTLCache

from app.config import settings
from app.dependencies import get_supabase, get_groq, get_current_user_id
from app.models import (
    GrowPlanRequest, GeneratePlanResponse, ErrorResponse, RateLimitError
)
from app.services.rag_service import RAGService
from app.services.ai_service import AIService, AIServiceError

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/v1/grow", tags=["Grow"])

# Rate limiting: 10 requests per minute per user
rate_limit_cache: TTLCache = TTLCache(maxsize=1000, ttl=60)

# Response cache: cache plans for 5 minutes
plan_cache: TTLCache = TTLCache(maxsize=100, ttl=300)


def check_rate_limit(user_id: str, max_requests: int = 10) -> bool:
    """Check if user has exceeded rate limit."""
    current = rate_limit_cache.get(user_id, 0)
    if current >= max_requests:
        return False
    rate_limit_cache[user_id] = current + 1
    return True


def get_cache_key(request: GrowPlanRequest) -> str:
    """Generate cache key from request parameters."""
    return (
        f"{request.strain_name}:{request.seed_type.value}"
        f":{request.medium.value}:{request.light_wattage}"
    )


@router.post(
    "/generate-plan",
    response_model=GeneratePlanResponse,
    responses={
        429: {"model": RateLimitError},
        500: {"model": ErrorResponse},
    },
)
async def generate_grow_plan(
    request: GrowPlanRequest,
    supabase: Client = Depends(get_supabase),
    groq: Groq = Depends(get_groq),
    user_id: str = Depends(get_current_user_id),
):
    """
    Generate a personalized grow plan using AI.

    This endpoint:
    1. Verifies JWT authentication via Supabase
    2. Retrieves relevant knowledge using RAG
    3. Generates a complete grow plan with Groq AI
    4. Saves the plan to the database
    5. Returns the plan with timeline and tasks

    Rate limited to 10 requests per minute.
    """
    # Check rate limit
    if not check_rate_limit(user_id):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "success": False,
                "error": "Rate limit exceeded",
                "retry_after_seconds": 60,
            },
        )

    # Check cache
    cache_key = get_cache_key(request)
    cached_plan = plan_cache.get(cache_key)
    if cached_plan:
        logger.info("Returning cached plan for %s", request.strain_name)
        return GeneratePlanResponse(
            success=True,
            message="Plan retrieved from cache",
            plan=cached_plan,
            grow_id=None,
        )

    try:
        # Initialize services
        rag_service = RAGService(supabase)
        ai_service = AIService(groq)

        # Step 1: Get relevant context from knowledge base
        logger.info("Fetching RAG context for %s", request.strain_name)
        context = await rag_service.get_relevant_context(
            strain_name=request.strain_name,
            medium=request.medium.value,
            experience_level=request.experience_level.value,
            seed_type=request.seed_type.value,
        )

        # Step 2: Generate plan with AI
        logger.info("Generating AI plan for %s", request.strain_name)
        plan = await ai_service.generate_plan(request, context)

        # Step 3: Save to database (sync call wrapped in to_thread)
        grow_id = await _save_grow_to_database(supabase, user_id, request, plan)

        # Step 4: Cache the plan
        plan_cache[cache_key] = plan

        logger.info("Successfully generated plan for grow %s", grow_id)

        return GeneratePlanResponse(
            success=True,
            message="Grow plan generated successfully",
            plan=plan,
            grow_id=grow_id,
        )

    except AIServiceError as e:
        logger.error("AI service error: %s", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "success": False,
                "error": str(e),
                "code": "AI_GENERATION_FAILED",
            },
        )
    except Exception as e:
        logger.error("Unexpected error generating plan: %s", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "success": False,
                "error": "An unexpected error occurred",
                "code": "INTERNAL_ERROR",
            },
        )


async def _save_grow_to_database(
    supabase: Client,
    user_id: str,
    request: GrowPlanRequest,
    plan,
) -> Optional[str]:
    """Save the generated grow plan to Supabase.

    Uses asyncio.to_thread because supabase-py is synchronous.
    """
    try:
        total_days = plan.summary.total_duration_days
        end_date = request.start_date + timedelta(days=total_days)

        grow_data = {
            "user_id": user_id,
            "name": f"{request.strain_name} Grow",
            "strain_name": request.strain_name,
            "strain_type": request.seed_type.value,
            "medium": request.medium.value,
            "light_type": request.light_type,
            "light_wattage": request.light_wattage,
            "space_width_cm": request.space_width_cm,
            "space_length_cm": request.space_length_cm,
            "space_height_cm": request.space_height_cm,
            "start_date": request.start_date.isoformat(),
            "estimated_end_date": end_date.isoformat(),
            "current_phase": "germination",
            "status": "active",
            "ai_plan": plan.model_dump(mode="json"),
        }

        # Wrap synchronous Supabase call so we don't block the event loop
        result = await asyncio.to_thread(
            lambda: supabase.table("grows").insert(grow_data).execute()
        )

        if result.data:
            grow_id = result.data[0]["id"]
            logger.info("Saved grow to database: %s", grow_id)
            return grow_id

        logger.warning("Failed to get grow ID from insert")
        return None

    except Exception as e:
        logger.error("Failed to save grow to database: %s", e)
        return None


@router.get("/plans/{grow_id}")
async def get_grow_plan(
    grow_id: str,
    supabase: Client = Depends(get_supabase),
    _user_id: str = Depends(get_current_user_id),
):
    """Retrieve a saved grow plan by ID."""
    try:
        result = await asyncio.to_thread(
            lambda: supabase.table("grows")
            .select("*")
            .eq("id", grow_id)
            .execute()
        )

        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"error": "Grow plan not found", "code": "NOT_FOUND"},
            )

        return {"success": True, "grow": result.data[0]}

    except HTTPException:
        raise
    except Exception as e:
        logger.error("Error retrieving grow plan: %s", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": "Failed to retrieve grow plan",
                "code": "INTERNAL_ERROR",
            },
        )


@router.get("/user/active")
async def get_active_grows(
    supabase: Client = Depends(get_supabase),
    user_id: str = Depends(get_current_user_id),
):
    """Get all active grows for the current user."""
    try:
        result = await asyncio.to_thread(
            lambda: supabase.table("grows")
            .select(
                "id, name, strain_name, current_phase, status, "
                "start_date, ai_plan"
            )
            .eq("user_id", user_id)
            .eq("status", "active")
            .order("created_at", desc=True)
            .execute()
        )

        return {"success": True, "grows": result.data or []}

    except Exception as e:
        logger.error("Error fetching active grows: %s", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": "Failed to fetch grows",
                "code": "INTERNAL_ERROR",
            },
        )
