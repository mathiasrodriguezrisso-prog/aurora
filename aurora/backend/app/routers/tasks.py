"""
📁 backend/app/routers/tasks.py
Tasks router — endpoints for daily task management and generation.
"""

import asyncio
import logging
from datetime import datetime, date
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field

from app.dependencies import get_supabase_client, get_current_user_id

logger = logging.getLogger("aurora.tasks")

router = APIRouter(prefix="/tasks", tags=["Tasks"])


# ── Pydantic Models ─────────────────────────────────────────────

class TaskResponse(BaseModel):
    id: str
    grow_id: str
    title: str
    description: Optional[str] = None
    scheduled_time: Optional[str] = None
    is_completed: bool = False
    is_critical: bool = False
    task_date: str
    created_at: str

class ToggleTaskRequest(BaseModel):
    is_completed: bool


# ── Get Today's Tasks ───────────────────────────────────────────

@router.get("/today")
async def get_today_tasks(
    grow_id: Optional[str] = None,
    user_id: str = Depends(get_current_user_id),
):
    """Get today's tasks for the user, optionally filtered by grow."""
    sb = get_supabase_client()
    today = date.today().isoformat()

    try:
        query = (
            sb.table("daily_tasks")
            .select("*")
            .eq("user_id", user_id)
            .eq("task_date", today)
            .order("is_critical", desc=True)
            .order("scheduled_time", desc=False)
        )

        if grow_id:
            query = query.eq("grow_id", grow_id)

        result = await asyncio.to_thread(query.execute)
        return {"tasks": result.data, "date": today}

    except Exception as e:
        logger.error("Get tasks error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})


# ── Toggle Task Completion ──────────────────────────────────────

@router.patch("/{task_id}")
async def toggle_task(
    task_id: str,
    body: ToggleTaskRequest,
    user_id: str = Depends(get_current_user_id),
):
    """Toggle a task's completion status."""
    sb = get_supabase_client()

    try:
        result = await asyncio.to_thread(
            sb.table("daily_tasks")
            .update({
                "is_completed": body.is_completed,
                "completed_at": datetime.utcnow().isoformat() if body.is_completed else None,
            })
            .eq("id", task_id)
            .eq("user_id", user_id)
            .execute
        )

        if not result.data:
            raise HTTPException(404, detail={"error": "Task not found"})

        # Gamification: award XP when task is completed
        if body.is_completed:
            try:
                from app.services.gamification_service import award_xp, check_achievements
                await award_xp(sb, user_id, 15, "complete_task")
                await check_achievements(sb, user_id)
            except Exception:
                pass  # Non-critical

        return result.data[0]

    except HTTPException:
        raise
    except Exception as e:
        logger.error("Toggle task error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})


# ── Generate Daily Tasks ────────────────────────────────────────

@router.post("/generate")
async def generate_daily_tasks(
    user_id: str = Depends(get_current_user_id),
):
    """
    Generate daily tasks based on active grow plans.
    This is called by the cron service but can also be triggered manually.
    """
    sb = get_supabase_client()
    today = date.today().isoformat()

    try:
        # Check if tasks already exist for today
        existing = await asyncio.to_thread(
            sb.table("daily_tasks")
            .select("id", count="exact")
            .eq("user_id", user_id)
            .eq("task_date", today)
            .execute
        )

        if (existing.count or 0) > 0:
            return {"message": "Tasks already generated for today", "count": existing.count}

        # Get active grows
        grows = await asyncio.to_thread(
            sb.table("grows")
            .select("*, grow_plans(*)")
            .eq("user_id", user_id)
            .eq("status", "active")
            .execute
        )

        tasks_created = 0
        for grow in grows.data:
            grow_id = grow["id"]
            plan = grow.get("grow_plans")

            # Generate standard daily tasks
            daily_tasks = [
                {
                    "user_id": user_id,
                    "grow_id": grow_id,
                    "title": "Check plant health",
                    "description": "Inspect leaves for discoloration, pests, or deficiencies",
                    "scheduled_time": "08:00",
                    "is_critical": False,
                    "task_date": today,
                },
                {
                    "user_id": user_id,
                    "grow_id": grow_id,
                    "title": "Log environmental data",
                    "description": "Record temperature, humidity, and pH readings",
                    "scheduled_time": "09:00",
                    "is_critical": True,
                    "task_date": today,
                },
                {
                    "user_id": user_id,
                    "grow_id": grow_id,
                    "title": "Water check",
                    "description": "Check soil moisture and water if needed",
                    "scheduled_time": "10:00",
                    "is_critical": False,
                    "task_date": today,
                },
                {
                    "user_id": user_id,
                    "grow_id": grow_id,
                    "title": "Take daily photo",
                    "description": "Document plant growth with a photo",
                    "scheduled_time": "12:00",
                    "is_critical": False,
                    "task_date": today,
                },
            ]

            # Insert all tasks
            await asyncio.to_thread(
                sb.table("daily_tasks").insert(daily_tasks).execute
            )
            tasks_created += len(daily_tasks)

            # Send push notification for new tasks
            if daily_tasks:
                try:
                    from app.services.push_service import send_push_notification
                    await send_push_notification(
                        user_id=user_id,
                        title="📋 New Daily Tasks",
                        body=f"You have {len(daily_tasks)} new tasks for your {strainName or 'grow'} today.",
                        data={"type": "task", "grow_id": grow_id},
                    )
                except Exception as e:
                    logger.error("Failed to send task push notification: %s", e)

        return {"message": f"Generated {tasks_created} tasks", "count": tasks_created}

    except Exception as e:
        logger.error("Generate tasks error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})


# ── Task History ────────────────────────────────────────────────

@router.get("/history")
async def get_task_history(
    days: int = Query(7, ge=1, le=30),
    user_id: str = Depends(get_current_user_id),
):
    """Get task completion history for the last N days."""
    sb = get_supabase_client()

    try:
        from datetime import timedelta
        start_date = (date.today() - timedelta(days=days)).isoformat()

        result = await asyncio.to_thread(
            sb.table("daily_tasks")
            .select("task_date, is_completed")
            .eq("user_id", user_id)
            .gte("task_date", start_date)
            .order("task_date", desc=True)
            .execute
        )

        # Aggregate by date
        history: dict = {}
        for task in result.data:
            d = task["task_date"]
            if d not in history:
                history[d] = {"date": d, "total": 0, "completed": 0}
            history[d]["total"] += 1
            if task["is_completed"]:
                history[d]["completed"] += 1

        return {"history": list(history.values())}

    except Exception as e:
        logger.error("Task history error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})
