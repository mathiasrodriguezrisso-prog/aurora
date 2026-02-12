"""
📁 backend/app/routers/users.py
User profiles — endpoints for profile management and settings.
"""

import asyncio
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.dependencies import get_supabase_client, get_current_user_id

logger = logging.getLogger("aurora.users")

router = APIRouter(prefix="/users", tags=["Users"])


# ── Pydantic Models ─────────────────────────────────────────────

class UpdateProfileRequest(BaseModel):
    display_name: Optional[str] = Field(None, max_length=50)
    bio: Optional[str] = Field(None, max_length=250)
    avatar_url: Optional[str] = None
    experience_level: Optional[str] = None
    grow_style: Optional[str] = None
    location: Optional[str] = Field(None, max_length=100)

class UserSettingsRequest(BaseModel):
    push_notifications: Optional[bool] = None
    email_notifications: Optional[bool] = None
    dark_mode: Optional[bool] = None
    measurement_unit: Optional[str] = None  # 'metric' | 'imperial'
    language: Optional[str] = None


# ── Profile Endpoints ───────────────────────────────────────────

@router.get("/me")
async def get_my_profile(user_id: str = Depends(get_current_user_id)):
    """Get the current user's profile."""
    sb = get_supabase_client()

    try:
        result = await asyncio.to_thread(
            sb.table("profiles")
            .select("*")
            .eq("id", user_id)
            .single()
            .execute
        )
        return result.data

    except Exception as e:
        logger.error("Get profile error: %s", e)
        raise HTTPException(404, detail={"error": "Profile not found"})


@router.patch("/me")
async def update_my_profile(
    body: UpdateProfileRequest,
    user_id: str = Depends(get_current_user_id),
):
    """Update the current user's profile."""
    sb = get_supabase_client()
    update_data = body.model_dump(exclude_none=True)

    if not update_data:
        raise HTTPException(400, detail={"error": "No fields to update"})

    try:
        result = await asyncio.to_thread(
            sb.table("profiles")
            .update(update_data)
            .eq("id", user_id)
            .execute
        )
        return result.data[0] if result.data else {"updated": True}

    except Exception as e:
        logger.error("Update profile error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})


@router.get("/{user_id}")
async def get_user_profile(
    user_id: str,
    current_user_id: str = Depends(get_current_user_id),
):
    """Get another user's public profile."""
    sb = get_supabase_client()

    try:
        result = await asyncio.to_thread(
            sb.table("profiles")
            .select("id, display_name, avatar_url, bio, experience_level, grow_style, created_at")
            .eq("id", user_id)
            .single()
            .execute
        )

        # Get their post count
        posts_result = await asyncio.to_thread(
            sb.table("posts")
            .select("id", count="exact")
            .eq("user_id", user_id)
            .execute
        )

        # Get follower and following counts
        followers_result = await asyncio.to_thread(
            sb.table("followers")
            .select("id", count="exact")
            .eq("following_id", user_id)
            .execute
        )
        following_result = await asyncio.to_thread(
            sb.table("followers")
            .select("id", count="exact")
            .eq("follower_id", user_id)
            .execute
        )

        # Check if current user follows this user
        is_following = False
        if current_user_id != user_id:
            check = await asyncio.to_thread(
                sb.table("followers")
                .select("id")
                .eq("follower_id", current_user_id)
                .eq("following_id", user_id)
                .maybeSingle()
                .execute
            )
            is_following = check.data is not None

        return {
            **result.data,
            "posts_count": posts_result.count or 0,
            "followers_count": followers_result.count or 0,
            "following_count": following_result.count or 0,
            "is_following": is_following,
        }

    except Exception as e:
        logger.error("Get user profile error: %s", e)
        raise HTTPException(404, detail={"error": "User not found"})


# ── Follow / Unfollow ──────────────────────────────────────────

@router.post("/{target_user_id}/follow")
async def follow_user(
    target_user_id: str,
    user_id: str = Depends(get_current_user_id),
):
    """Follow a user."""
    if target_user_id == user_id:
        raise HTTPException(400, detail={"error": "Cannot follow yourself"})

    sb = get_supabase_client()

    try:
        # Check if already following
        existing = await asyncio.to_thread(
            sb.table("followers")
            .select("id")
            .eq("follower_id", user_id)
            .eq("following_id", target_user_id)
            .maybeSingle()
            .execute
        )

        if existing.data:
            return {"following": True, "message": "Already following"}

        await asyncio.to_thread(
            sb.table("followers").insert({
                "follower_id": user_id,
                "following_id": target_user_id,
            }).execute
        )

        return {"following": True}

    except Exception as e:
        logger.error("Follow error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})


@router.delete("/{target_user_id}/follow")
async def unfollow_user(
    target_user_id: str,
    user_id: str = Depends(get_current_user_id),
):
    """Unfollow a user."""
    sb = get_supabase_client()

    try:
        await asyncio.to_thread(
            sb.table("followers")
            .delete()
            .eq("follower_id", user_id)
            .eq("following_id", target_user_id)
            .execute
        )
        return {"following": False}

    except Exception as e:
        logger.error("Unfollow error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})


@router.get("/{user_id}/posts")
async def get_user_posts(
    user_id: str,
    current_user_id: str = Depends(get_current_user_id),
):
    """Get a user's public posts."""
    sb = get_supabase_client()

    try:
        result = await asyncio.to_thread(
            sb.table("posts")
            .select("*")
            .eq("user_id", user_id)
            .order("created_at", desc=True)
            .limit(30)
            .execute
        )
        return result.data

    except Exception as e:
        logger.error("Get user posts error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})


# ── Settings ────────────────────────────────────────────────────

@router.get("/me/settings")
async def get_settings(user_id: str = Depends(get_current_user_id)):
    """Get user settings."""
    sb = get_supabase_client()

    try:
        result = await asyncio.to_thread(
            sb.table("user_settings")
            .select("*")
            .eq("user_id", user_id)
            .maybeSingle()
            .execute
        )

        if not result.data:
            # Create default settings
            defaults = {
                "user_id": user_id,
                "push_notifications": True,
                "email_notifications": True,
                "dark_mode": True,
                "measurement_unit": "metric",
                "language": "en",
            }
            await asyncio.to_thread(
                sb.table("user_settings").insert(defaults).execute
            )
            return defaults

        return result.data

    except Exception as e:
        logger.error("Get settings error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})


@router.patch("/me/settings")
async def update_settings(
    body: UserSettingsRequest,
    user_id: str = Depends(get_current_user_id),
):
    """Update user settings."""
    sb = get_supabase_client()
    update_data = body.model_dump(exclude_none=True)

    if not update_data:
        raise HTTPException(400, detail={"error": "No fields to update"})

    try:
        result = await asyncio.to_thread(
            sb.table("user_settings")
            .update(update_data)
            .eq("user_id", user_id)
            .execute
        )
        return result.data[0] if result.data else {"updated": True}

    except Exception as e:
        logger.error("Update settings error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})


# ── User Stats ──────────────────────────────────────────────────

@router.get("/me/stats")
async def get_my_stats(user_id: str = Depends(get_current_user_id)):
    """Get user statistics (grows, posts, karma)."""
    sb = get_supabase_client()

    try:
        grows, posts, likes = await asyncio.gather(
            asyncio.to_thread(
                sb.table("grows")
                .select("id", count="exact")
                .eq("user_id", user_id)
                .execute
            ),
            asyncio.to_thread(
                sb.table("posts")
                .select("id", count="exact")
                .eq("user_id", user_id)
                .execute
            ),
            asyncio.to_thread(
                sb.table("post_likes")
                .select("id", count="exact")
                .eq("user_id", user_id)
                .execute
            ),
        )

        return {
            "total_grows": grows.count or 0,
            "total_posts": posts.count or 0,
            "total_likes_received": likes.count or 0,
            "karma": (grows.count or 0) * 10 + (posts.count or 0) * 5 + (likes.count or 0),
        }

    except Exception as e:
        logger.error("Get stats error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})
