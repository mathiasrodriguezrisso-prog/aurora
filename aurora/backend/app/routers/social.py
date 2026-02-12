"""
📁 backend/app/routers/social.py
Social module — endpoints for community feed, posts, likes, comments, reports.
"""

import asyncio
import logging
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field

from cachetools import TTLCache

from app.dependencies import get_supabase_client, get_current_user_id, get_groq_client
from app.services.ai_service import AIService

logger = logging.getLogger("aurora.social")

router = APIRouter(prefix="/social", tags=["Social"])

# Rate limiting: 30 requests per minute per user for social actions
rate_limit_cache: TTLCache = TTLCache(maxsize=1000, ttl=60)


def check_rate_limit(user_id: str, max_requests: int = 30) -> bool:
    """Check if user has exceeded rate limit for social actions."""
    current = rate_limit_cache.get(user_id, 0)
    if current >= max_requests:
        return False
    rate_limit_cache[user_id] = current + 1
    return True


# ── Pydantic Models ─────────────────────────────────────────────

class CreatePostRequest(BaseModel):
    content: str = Field(..., min_length=1, max_length=2000)
    image_urls: list[str] = Field(default_factory=list, max_length=5)
    strain_tag: Optional[str] = None
    grow_id: Optional[str] = None
    day_number: Optional[int] = None

class PostResponse(BaseModel):
    id: str
    user_id: str
    content: str
    image_urls: list[str]
    strain_tag: Optional[str]
    grow_id: Optional[str]
    day_number: Optional[int]
    likes_count: int
    comments_count: int
    created_at: str
    author_username: Optional[str] = None
    author_avatar: Optional[str] = None
    is_liked: bool = False
    tech_score: Optional[float] = None
    is_toxic: bool = False
    is_hidden: bool = False

class CommentRequest(BaseModel):
    content: str = Field(..., min_length=1, max_length=500)

class CommentResponse(BaseModel):
    id: str
    post_id: str
    user_id: str
    content: str
    created_at: str
    author_username: Optional[str] = None
    author_avatar: Optional[str] = None
    is_hidden: bool = False
    is_flagged: bool = False
    is_toxic: bool = False

class ReportRequest(BaseModel):
    reason: str = Field(..., min_length=1, max_length=500)
    post_id: Optional[str] = None
    comment_id: Optional[str] = None


# ── Feed Endpoint ───────────────────────────────────────────────

@router.get("/feed")
async def get_feed(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=50),
    strain: Optional[str] = None,
    filter: Optional[str] = Query(None, description="trending|recent|following|questions"),
    user_id: str = Depends(get_current_user_id),
):
    """Get the community feed with pagination and optional strain filter."""
    sb = get_supabase_client()
    offset = (page - 1) * limit

    try:
        query = sb.table("posts").select(
            "*, profiles!posts_user_id_fkey(display_name, avatar_url)"
        ).eq("is_hidden", False)

        if strain:
            query = query.eq("strain_tag", strain)

        # For basic "recent" filter, we can do it at DB level
        if filter == "recent" or not filter:
            query = query.order("created_at", desc=True).range(offset, offset + limit - 1)
            result = await asyncio.to_thread(query.execute)
            raw_posts = result.data
        else:
            # For "trending" or other complex sorts, we might need to fetch a larger batch 
            # and sort in memory, or implement a calculated column in DB.
            # Here we'll fetch more and score in memory for simplicity in this MVP step.
            query = query.order("created_at", desc=True).limit(200)
            result = await asyncio.to_thread(query.execute)
            raw_posts = result.data

            if filter == "trending":
                # Smart Scoring Formula:
                # Score = (likes * 0.3) + (tech_score * 0.4) + (comments * 0.1) + (recency * 0.2)
                
                now = datetime.utcnow()
                for p in raw_posts:
                    likes = p.get("likes_count", 0)
                    tech_score = p.get("tech_score", 0) or 0
                    comments = p.get("comments_count", 0)
                    
                    # Recency: 1.0 for brand new, decaying to 0 over 7 days
                    created_at = datetime.fromisoformat(p["created_at"].replace("Z", "+00:00")).replace(tzinfo=None)
                    age_hours = (now - created_at).total_seconds() / 3600
                    recency = max(0, 1 - (age_hours / (24 * 7))) 
                    
                    p["_score"] = (likes * 0.3) + (tech_score * 0.4) + (comments * 0.1) + (recency * 10) # Weighted recency
                
                raw_posts.sort(key=lambda x: x.get("_score", 0), reverse=True)
                # Slice for pagination
                raw_posts = raw_posts[offset : offset + limit]

        # Check which posts the user has liked
        post_ids = [p["id"] for p in raw_posts]
        liked_ids = set()
        if post_ids:
            likes_result = await asyncio.to_thread(
                sb.table("post_likes")
                .select("post_id")
                .eq("user_id", user_id)
                .in_("post_id", post_ids)
                .execute
            )
            liked_ids = {l["post_id"] for l in likes_result.data}

        posts = []
        for p in raw_posts:
            profile = p.pop("profiles", {}) or {}
            posts.append({
                **p,
                "author_username": profile.get("display_name"),
                "author_avatar": profile.get("avatar_url"),
                "is_liked": p["id"] in liked_ids,
                "tech_score": p.get("tech_score"),
                "smart_score": p.get("_score"),
            })

        return {"posts": posts, "page": page, "has_more": len(raw_posts) == limit}

    except Exception as e:
        logger.error("Feed error: %s", e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": "Failed to load feed",
                "detail": "Please check your pagination parameters and try again.",
                "code": "FEED_ERROR"
            }
        )


# ── Create Post ─────────────────────────────────────────────────

@router.post("/posts", status_code=status.HTTP_201_CREATED)
async def create_post(
    body: CreatePostRequest,
    user_id: str = Depends(get_current_user_id),
):
    """Create a new post."""
    sb = get_supabase_client()

    if not check_rate_limit(user_id):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "error": "Rate limit exceeded",
                "detail": "Max 30 social actions per minute. Please retry after 60 seconds.",
                "code": "RATE_001",
                "retry_after_seconds": 60
            }
        )

    try:
        # Toxicity check
        ai_service = AIService(get_groq_client())
        is_toxic = await ai_service.check_toxicity(body.content)

        result = await asyncio.to_thread(
            sb.table("posts").insert({
                "user_id": user_id,
                "content": body.content,
                "image_urls": body.image_urls,
                "strain_tag": body.strain_tag,
                "grow_id": body.grow_id,
                "day_number": body.day_number,
                "likes_count": 0,
                "comments_count": 0,
                "is_toxic": is_toxic,
                "is_hidden": is_toxic,  # Hide immediately if toxic
            }).execute
        )

        if is_toxic:
            logger.warning("Post from %s flagged as toxic", user_id)

        # Gamification: award XP for creating a post (only if not toxic)
        if not is_toxic:
            try:
                from app.services.gamification_service import award_xp, check_achievements
                await award_xp(sb, user_id, 10, "create_post")
                await check_achievements(sb, user_id)
            except Exception:
                pass  # Non-critical

        return result.data[0]

    except Exception as e:
        logger.error("Create post error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})


# ── Get Post Detail ─────────────────────────────────────────────

@router.get("/posts/{post_id}")
async def get_post(
    post_id: str,
    user_id: str = Depends(get_current_user_id),
):
    """Get a single post with its details."""
    sb = get_supabase_client()

    try:
        result = await asyncio.to_thread(
            sb.table("posts")
            .select("*, profiles!posts_user_id_fkey(display_name, avatar_url)")
            .eq("id", post_id)
            .single()
            .execute
        )

        post = result.data
        if post.get("is_hidden") and post.get("user_id") != user_id:
             raise HTTPException(404, detail="Post not found")

        profile = post.pop("profiles", {}) or {}

        # Check if user liked it
        like_result = await asyncio.to_thread(
            sb.table("post_likes")
            .select("id")
            .eq("post_id", post_id)
            .eq("user_id", user_id)
            .execute
        )

        return {
            **post,
            "author_username": profile.get("display_name"),
            "author_avatar": profile.get("avatar_url"),
            "is_liked": len(like_result.data) > 0,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error("Get post error: %s", e)
        raise HTTPException(404, detail={"error": "Post not found"})


# ── Like / Unlike ───────────────────────────────────────────────

@router.post("/posts/{post_id}/like")
async def toggle_like(
    post_id: str,
    user_id: str = Depends(get_current_user_id),
):
    """Toggle like on a post."""
    sb = get_supabase_client()

    try:
        # Check existing like
        existing = await asyncio.to_thread(
            sb.table("post_likes")
            .select("id")
            .eq("post_id", post_id)
            .eq("user_id", user_id)
            .execute
        )

        if existing.data:
            # Unlike
            await asyncio.to_thread(
                sb.table("post_likes")
                .delete()
                .eq("post_id", post_id)
                .eq("user_id", user_id)
                .execute
            )
            await asyncio.to_thread(
                sb.rpc("decrement_likes", {"post_id_param": post_id}).execute
            )
            return {"liked": False}
        else:
            # Like
            await asyncio.to_thread(
                sb.table("post_likes")
                .insert({"post_id": post_id, "user_id": user_id})
                .execute
            )
            await asyncio.to_thread(
                sb.rpc("increment_likes", {"post_id_param": post_id}).execute
            )

            # Gamification: award karma to post author
            try:
                from app.services.gamification_service import award_karma
                post_data = await asyncio.to_thread(
                    sb.table("posts").select("user_id").eq("id", post_id).single().execute
                )
                post_author = post_data.data.get("user_id")
                if post_author and post_author != user_id:
                    await award_karma(sb, post_author, 2, "receive_like")
            except Exception:
                pass  # Non-critical

            return {"liked": True}

    except Exception as e:
        logger.error("Like error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})


# ── Comments ────────────────────────────────────────────────────

@router.get("/posts/{post_id}/comments")
async def get_comments(
    post_id: str,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=50),
    user_id: str = Depends(get_current_user_id),
):
    """Get comments for a post."""
    sb = get_supabase_client()
    offset = (page - 1) * limit

    try:
        result = await asyncio.to_thread(
            sb.table("post_comments")
            .select("*, profiles!post_comments_user_id_fkey(display_name, avatar_url)")
            .eq("post_id", post_id)
            .eq("is_hidden", False)
            .order("created_at", desc=False)
            .range(offset, offset + limit - 1)
            .execute
        )

        comments = []
        for c in result.data:
            profile = c.pop("profiles", {}) or {}
            comments.append({
                **c,
                "author_username": profile.get("display_name"),
                "author_avatar": profile.get("avatar_url"),
                "is_hidden": c.get("is_hidden", False),
                "is_flagged": c.get("is_flagged", False),
            })

        return {"comments": comments, "page": page}

    except Exception as e:
        logger.error("Comments error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})


@router.post("/posts/{post_id}/comments", status_code=status.HTTP_201_CREATED)
async def create_comment(
    post_id: str,
    body: CommentRequest,
    user_id: str = Depends(get_current_user_id),
):
    """Add a comment to a post."""
    sb = get_supabase_client()

    if not check_rate_limit(user_id):
        raise HTTPException(status.HTTP_429_TOO_MANY_REQUESTS, detail="Rate limit exceeded")

    try:
        # Toxicity check
        ai_service = AIService(get_groq_client())
        is_toxic = await ai_service.check_toxicity(body.content)

        result = await asyncio.to_thread(
            sb.table("post_comments").insert({
                "post_id": post_id,
                "user_id": user_id,
                "content": body.content,
                "is_toxic": is_toxic,
                "is_hidden": is_toxic,
            }).execute
        )

        if is_toxic:
            logger.warning("Comment from %s flagged as toxic", user_id)

        # Increment comments count (only if not toxic or hidden)
        if not is_toxic:
            await asyncio.to_thread(
                sb.rpc("increment_comments", {"post_id_param": post_id}).execute
            )

        # Gamification: award XP for commenting (only if not toxic)
        if not is_toxic:
            try:
                from app.services.gamification_service import award_xp
                await award_xp(sb, user_id, 5, "create_comment")
            except Exception:
                pass  # Non-critical

        return result.data[0]

    except Exception as e:
        logger.error("Create comment error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})


# ── Report ──────────────────────────────────────────────────────

@router.post("/report", status_code=status.HTTP_201_CREATED)
async def report_content(
    body: ReportRequest,
    user_id: str = Depends(get_current_user_id),
):
    """Report a post or comment."""
    sb = get_supabase_client()

    try:
        await asyncio.to_thread(
            sb.table("reports").insert({
                "reporter_id": user_id,
                "reason": body.reason,
                "post_id": body.post_id,
                "comment_id": body.comment_id,
                "status": "pending",
            }).execute
        )
        return {"reported": True}

    except Exception as e:
        logger.error("Report error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})


# ── Competitive Analysis ────────────────────────────────────────

@router.get("/competitive-analysis")
async def competitive_analysis(
    user_id: str = Depends(get_current_user_id),
):
    """
    Get competitive analysis — compare user's stats against
    community averages and show percentile ranking.
    """
    sb = get_supabase_client()

    try:
        # User's stats
        user_posts = await asyncio.to_thread(
            sb.table("posts").select("id", count="exact")
            .eq("user_id", user_id).execute
        )
        user_grows = await asyncio.to_thread(
            sb.table("grows").select("id, yield_grams", count="exact")
            .eq("user_id", user_id).eq("status", "completed").execute
        )
        user_tasks = await asyncio.to_thread(
            sb.table("daily_tasks").select("id, is_completed", count="exact")
            .eq("user_id", user_id).execute
        )
        user_profile = await asyncio.to_thread(
            sb.table("profiles").select("total_xp, karma, level")
            .eq("id", user_id).single().execute
        )

        # Community totals
        total_users = await asyncio.to_thread(
            sb.table("profiles").select("id", count="exact").execute
        )
        community_posts = await asyncio.to_thread(
            sb.table("posts").select("id", count="exact").execute
        )
        community_grows = await asyncio.to_thread(
            sb.table("grows").select("id", count="exact")
            .eq("status", "completed").execute
        )

        num_users = max(total_users.count or 1, 1)

        # Calculate user metrics
        user_yield_data = user_grows.data or []
        user_avg_yield = (
            sum(g.get("yield_grams", 0) or 0 for g in user_yield_data)
            / max(len(user_yield_data), 1)
        )
        user_completed_tasks = sum(
            1 for t in (user_tasks.data or []) if t.get("is_completed")
        )
        user_total_tasks = user_tasks.count or 0
        user_task_rate = (
            user_completed_tasks / max(user_total_tasks, 1) * 100
        )

        # Community averages
        avg_posts = (community_posts.count or 0) / num_users
        avg_grows = (community_grows.count or 0) / num_users

        profile = user_profile.data or {}

        return {
            "user_stats": {
                "posts_count": user_posts.count or 0,
                "completed_grows": user_grows.count or 0,
                "avg_yield_grams": round(user_avg_yield, 1),
                "task_completion_rate": round(user_task_rate, 1),
                "total_xp": profile.get("total_xp", 0),
                "karma": profile.get("karma", 0),
                "level": profile.get("level", 1),
            },
            "community_averages": {
                "avg_posts_per_user": round(avg_posts, 1),
                "avg_grows_per_user": round(avg_grows, 1),
                "total_active_users": num_users,
            },
            "comparison": {
                "posts_vs_avg": round(
                    ((user_posts.count or 0) / max(avg_posts, 0.1) - 1) * 100,
                    1,
                ),
                "grows_vs_avg": round(
                    ((user_grows.count or 0) / max(avg_grows, 0.1) - 1) * 100,
                    1,
                ),
            },
        }

    except Exception as e:
        logger.error("Competitive analysis error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})
