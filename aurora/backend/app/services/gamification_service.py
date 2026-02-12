"""
📁 backend/app/services/gamification_service.py
Gamification engine — XP, Karma, Levels, and Achievement tracking.
"""

import logging
import math
from typing import Optional

from supabase import Client

logger = logging.getLogger("aurora.gamification")


# ── Level Curve ────────────────────────────────────────────────

def xp_for_level(level: int) -> int:
    """XP needed to reach a given level. Quadratic curve."""
    return int(100 * (level ** 1.5))


def level_from_xp(total_xp: int) -> int:
    """Calculate current level from total XP."""
    level = 1
    while xp_for_level(level + 1) <= total_xp:
        level += 1
    return level


# ── XP Constants ───────────────────────────────────────────────

XP_REWARDS = {
    "create_post": 10,
    "receive_like": 3,
    "create_comment": 5,
    "complete_task": 15,
    "submit_sensor_reading": 8,
    "daily_login": 5,
    "complete_grow": 200,
    "first_post": 50,           # bonus
    "first_harvest": 100,       # bonus
    "community_helpful": 20,    # tech_score > 7
}

KARMA_REWARDS = {
    "receive_like": 2,
    "helpful_answer": 5,        # tech_score > 7
    "create_quality_post": 3,   # tech_score > 5
    "daily_streak": 1,
}


# ── Core Functions ─────────────────────────────────────────────

async def award_xp(
    supabase: Client,
    user_id: str,
    amount: int,
    reason: str,
) -> dict:
    """
    Award XP to a user and check for level-up.
    Returns: { xp_before, xp_after, level_before, level_after, leveled_up }
    """
    try:
        # Get current profile
        result = supabase.table("profiles").select(
            "total_xp, level"
        ).eq("id", user_id).single().execute()

        profile = result.data
        xp_before = profile.get("total_xp", 0) or 0
        level_before = profile.get("level", 1) or 1

        xp_after = xp_before + amount
        level_after = level_from_xp(xp_after)
        leveled_up = level_after > level_before

        # Update profile
        supabase.table("profiles").update({
            "total_xp": xp_after,
            "level": level_after,
        }).eq("id", user_id).execute()

        # Log XP event
        supabase.table("xp_events").insert({
            "user_id": user_id,
            "amount": amount,
            "reason": reason,
            "total_after": xp_after,
        }).execute()

        if leveled_up:
            logger.info(
                "🎉 User %s leveled up: %d → %d (XP: %d)",
                user_id[:8], level_before, level_after, xp_after,
            )

        return {
            "xp_before": xp_before,
            "xp_after": xp_after,
            "xp_gained": amount,
            "level_before": level_before,
            "level_after": level_after,
            "leveled_up": leveled_up,
            "xp_to_next": xp_for_level(level_after + 1) - xp_after,
        }

    except Exception as e:
        logger.error("Failed to award XP to %s: %s", user_id[:8], e)
        return {}


async def award_karma(
    supabase: Client,
    user_id: str,
    amount: int,
    reason: str,
) -> dict:
    """Award Karma points to a user."""
    try:
        result = supabase.table("profiles").select(
            "karma"
        ).eq("id", user_id).single().execute()

        karma_before = result.data.get("karma", 0) or 0
        karma_after = karma_before + amount

        supabase.table("profiles").update({
            "karma": karma_after,
        }).eq("id", user_id).execute()

        logger.info(
            "⭐ Karma awarded: user=%s amount=%d reason=%s",
            user_id[:8], amount, reason,
        )

        return {
            "karma_before": karma_before,
            "karma_after": karma_after,
            "karma_gained": amount,
        }

    except Exception as e:
        logger.error("Failed to award karma to %s: %s", user_id[:8], e)
        return {}


async def check_achievements(
    supabase: Client,
    user_id: str,
) -> list[dict]:
    """
    Check and unlock any achievements the user has earned.
    Returns list of newly unlocked achievements.
    """
    newly_unlocked = []

    try:
        # Get all achievements
        all_achievements = supabase.table("achievements").select(
            "*"
        ).execute()

        # Get user's already-unlocked achievements
        unlocked = supabase.table("user_achievements").select(
            "achievement_id"
        ).eq("user_id", user_id).execute()

        unlocked_ids = {a["achievement_id"] for a in (unlocked.data or [])}

        # Get user stats
        profile = supabase.table("profiles").select(
            "total_xp, karma, level"
        ).eq("id", user_id).single().execute()

        stats = profile.data

        # Count various metrics for condition checking
        post_count = supabase.table("posts").select(
            "id", count="exact"
        ).eq("user_id", user_id).execute()

        task_count = supabase.table("daily_tasks").select(
            "id", count="exact"
        ).eq("user_id", user_id).eq("is_completed", True).execute()

        sensor_count = supabase.table("sensor_readings").select(
            "id", count="exact"
        ).eq("user_id", user_id).execute()

        grow_count = supabase.table("grows").select(
            "id", count="exact"
        ).eq("user_id", user_id).eq("status", "completed").execute()

        metrics = {
            "total_xp": stats.get("total_xp", 0) or 0,
            "karma": stats.get("karma", 0) or 0,
            "level": stats.get("level", 1) or 1,
            "posts_created": post_count.count or 0,
            "tasks_completed": task_count.count or 0,
            "sensor_readings": sensor_count.count or 0,
            "grows_completed": grow_count.count or 0,
        }

        for achievement in (all_achievements.data or []):
            a_id = achievement["id"]
            if a_id in unlocked_ids:
                continue

            condition = achievement.get("condition", {})
            if _check_condition(condition, metrics):
                # Unlock!
                supabase.table("user_achievements").insert({
                    "user_id": user_id,
                    "achievement_id": a_id,
                }).execute()

                # Award XP/Karma bonus
                reward_xp = achievement.get("reward_xp", 0) or 0
                reward_karma = achievement.get("reward_karma", 0) or 0

                if reward_xp > 0:
                    await award_xp(
                        supabase, user_id, reward_xp,
                        f"achievement:{achievement['name']}"
                    )
                if reward_karma > 0:
                    await award_karma(
                        supabase, user_id, reward_karma,
                        f"achievement:{achievement['name']}"
                    )

                newly_unlocked.append(achievement)
                logger.info(
                    "🏆 Achievement unlocked: user=%s achievement=%s",
                    user_id[:8], achievement["name"],
                )

    except Exception as e:
        logger.error("Achievement check error for %s: %s", user_id[:8], e)

    return newly_unlocked


def _check_condition(condition: dict, metrics: dict) -> bool:
    """Evaluate an achievement condition against user metrics."""
    if not condition:
        return False

    metric_name = condition.get("metric", "")
    operator = condition.get("operator", ">=")
    threshold = condition.get("threshold", 0)

    value = metrics.get(metric_name, 0)

    if operator == ">=":
        return value >= threshold
    elif operator == ">":
        return value > threshold
    elif operator == "==":
        return value == threshold
    elif operator == "<=":
        return value <= threshold

    return False


async def award_weekly_bonuses(supabase: Client):
    """
    Award bonus XP to active users during the past week.
    Runs every Sunday.
    """
    logger.info("📅 [GAMIFICATION] Awarding weekly bonuses...")
    from datetime import datetime, timedelta

    one_week_ago = (datetime.utcnow() - timedelta(days=7)).isoformat()

    try:
        # Get users with at least 5 completed tasks this week
        active_users = supabase.table("daily_tasks").select(
            "user_id", count="exact"
        ).eq("is_completed", True).gte("completed_at", one_week_ago).execute()

        # Group by user and count
        counts = {}
        for item in (active_users.data or []):
            uid = item["user_id"]
            counts[uid] = counts.get(uid, 0) + 1

        for user_id, count in counts.items():
            if count >= 5:
                # Award "Consistent Grower" bonus
                await award_xp(supabase, user_id, 100, "weekly_consistency_bonus")
                await award_karma(supabase, user_id, 10, "weekly_consistency_bonus")

        logger.info("✅ Weekly bonuses awarded to %d users", len(counts))

    except Exception as e:
        logger.error("Failed to award weekly bonuses: %s", e)


async def reconcile_all_levels(supabase: Client):
    """
    Safety check to ensure all users have the correct level based on their XP.
    Runs weekly.
    """
    logger.info("🔄 [GAMIFICATION] Reconciling all user levels...")

    try:
        profiles = supabase.table("profiles").select("id, total_xp, level").execute()

        reconciled_count = 0
        for p in (profiles.data or []):
            user_id = p["id"]
            current_xp = p.get("total_xp", 0) or 0
            current_level = p.get("level", 1) or 1
            
            correct_level = level_from_xp(current_xp)

            if correct_level != current_level:
                await supabase.table("profiles").update({
                    "level": correct_level
                }).eq("id", user_id).execute()
                reconciled_count += 1
                logger.info("   Fixed level for user %s: %d → %d", user_id[:8], current_level, correct_level)

        logger.info("✅ Level reconciliation complete. %d profiles fixed.", reconciled_count)

    except Exception as e:
        logger.error("Failed to reconcile levels: %s", e)


async def award_weekly_bonuses(supabase: Client):
    """
    Award bonus XP to active users during the past week.
    Runs every Sunday.
    """
    logger.info("📅 [GAMIFICATION] Awarding weekly bonuses...")
    from datetime import datetime, timedelta

    one_week_ago = (datetime.utcnow() - timedelta(days=7)).isoformat()

    try:
        # Get users with at least 5 completed tasks this week
        active_users = supabase.table("daily_tasks").select(
            "user_id", count="exact"
        ).eq("is_completed", True).gte("completed_at", one_week_ago).execute()

        # Group by user and count
        counts = {}
        for item in (active_users.data or []):
            uid = item["user_id"]
            counts[uid] = counts.get(uid, 0) + 1

        for user_id, count in counts.items():
            if count >= 5:
                # Award "Consistent Grower" bonus
                await award_xp(supabase, user_id, 100, "weekly_consistency_bonus")
                await award_karma(supabase, user_id, 10, "weekly_consistency_bonus")

        logger.info("✅ Weekly bonuses awarded to %d users", len(counts))

    except Exception as e:
        logger.error("Failed to award weekly bonuses: %s", e)


async def reconcile_all_levels(supabase: Client):
    """
    Safety check to ensure all users have the correct level based on their XP.
    Runs weekly.
    """
    logger.info("🔄 [GAMIFICATION] Reconciling all user levels...")

    try:
        profiles = supabase.table("profiles").select("id, total_xp, level").execute()

        reconciled_count = 0
        for p in (profiles.data or []):
            user_id = p["id"]
            current_xp = p.get("total_xp", 0) or 0
            current_level = p.get("level", 1) or 1
            
            correct_level = level_from_xp(current_xp)

            if correct_level != current_level:
                await supabase.table("profiles").update({
                    "level": correct_level
                }).eq("id", user_id).execute()
                reconciled_count += 1
                logger.info("   Fixed level for user %s: %d → %d", user_id[:8], current_level, correct_level)

        logger.info("✅ Level reconciliation complete. %d profiles fixed.", reconciled_count)

    except Exception as e:
        logger.error("Failed to reconcile levels: %s", e)
