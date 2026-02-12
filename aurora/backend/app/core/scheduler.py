"""
📁 backend/app/core/scheduler.py
APScheduler integration for Aurora backend.
Runs periodic scheduled jobs:
  1. daily_tasks_generator — generates daily tasks at 00:00 UTC
  2. anomaly_checker — checks sensor anomalies every 6 hours
"""

import asyncio
import logging
from datetime import datetime

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.events import EVENT_JOB_ERROR, EVENT_JOB_EXECUTED

from app.dependencies import get_supabase_client, get_current_user_id

logger = logging.getLogger("aurora.scheduler")


# ── Job Functions ──────────────────────────────────────────────

async def generate_all_daily_tasks():
    """
    Generate daily tasks for ALL users with active grows.
    Runs at 00:00 UTC each day.
    """
    logger.info("🕛 [CRON] Starting daily task generation...")
    sb = get_supabase_client()

    try:
        # Get all users with active grows
        active_grows = sb.table("grows").select(
            "user_id"
        ).eq("status", "active").execute()

        if not active_grows.data:
            logger.info("   No active grows found. Skipping task generation.")
            return

        # Deduplicate user IDs
        user_ids = list({g["user_id"] for g in active_grows.data})
        logger.info("   Found %d users with active grows", len(user_ids))

        from datetime import date
        today = date.today().isoformat()
        total_tasks = 0

        for user_id in user_ids:
            try:
                # Check if tasks already exist for today
                existing = sb.table("daily_tasks").select(
                    "id", count="exact"
                ).eq("user_id", user_id).eq("task_date", today).execute()

                if (existing.count or 0) > 0:
                    logger.info("   ⏭️  User %s already has tasks for today", user_id[:8])
                    continue

                # Get user's active grows
                user_grows = sb.table("grows").select(
                    "id, strain_name, current_phase"
                ).eq("user_id", user_id).eq("status", "active").execute()

                for grow in user_grows.data:
                    grow_id = grow["id"]
                    phase = grow.get("current_phase", "vegetative")

                    # Generate tasks based on growth phase
                    tasks = _generate_tasks_for_phase(
                        user_id=user_id,
                        grow_id=grow_id,
                        phase=phase,
                        today=today,
                    )

                    if tasks:
                        sb.table("daily_tasks").insert(tasks).execute()
                        total_tasks += len(tasks)

            except Exception as e:
                logger.error("   Error generating tasks for user %s: %s", user_id[:8], e)
                continue

        logger.info("✅ [CRON] Daily tasks generated: %d tasks for %d users", total_tasks, len(user_ids))

    except Exception as e:
        logger.error("❌ [CRON] Daily task generation failed: %s", e)


def _generate_tasks_for_phase(
    user_id: str,
    grow_id: str,
    phase: str,
    today: str,
) -> list[dict]:
    """Generate appropriate daily tasks based on current growth phase."""
    base_tasks = [
        {
            "user_id": user_id,
            "grow_id": grow_id,
            "title": "Check plant health",
            "description": "Inspect leaves for discoloration, pests, or stress signs",
            "scheduled_time": "08:00",
            "is_critical": False,
            "is_completed": False,
            "task_date": today,
        },
        {
            "user_id": user_id,
            "grow_id": grow_id,
            "title": "Log environmental data",
            "description": "Record temperature, humidity, and VPD readings",
            "scheduled_time": "09:00",
            "is_critical": True,
            "is_completed": False,
            "task_date": today,
        },
        {
            "user_id": user_id,
            "grow_id": grow_id,
            "title": "Check water / moisture",
            "description": "Check soil moisture or reservoir levels, water if needed",
            "scheduled_time": "10:00",
            "is_critical": False,
            "is_completed": False,
            "task_date": today,
        },
        {
            "user_id": user_id,
            "grow_id": grow_id,
            "title": "Take daily photo",
            "description": "Document plant growth with a photo for the grow gallery",
            "scheduled_time": "12:00",
            "is_critical": False,
            "is_completed": False,
            "task_date": today,
        },
    ]

    # Phase-specific tasks
    if phase in ("vegetative", "veg"):
        base_tasks.append({
            "user_id": user_id,
            "grow_id": grow_id,
            "title": "Training check",
            "description": "Adjust LST ties, check SCROG screen, or plan next topping",
            "scheduled_time": "11:00",
            "is_critical": False,
            "is_completed": False,
            "task_date": today,
        })
    elif phase in ("flowering", "flower", "bloom"):
        base_tasks.append({
            "user_id": user_id,
            "grow_id": grow_id,
            "title": "Check trichomes",
            "description": "Use magnifier to check trichome color (clear → cloudy → amber)",
            "scheduled_time": "11:00",
            "is_critical": False,
            "is_completed": False,
            "task_date": today,
        })
        base_tasks.append({
            "user_id": user_id,
            "grow_id": grow_id,
            "title": "Inspect for mold",
            "description": "Check dense buds for signs of botrytis or powdery mildew",
            "scheduled_time": "14:00",
            "is_critical": True,
            "is_completed": False,
            "task_date": today,
        })
    elif phase in ("drying", "curing"):
        base_tasks = [
            {
                "user_id": user_id,
                "grow_id": grow_id,
                "title": "Check drying conditions",
                "description": "Verify 18-20°C and 55-65% humidity in drying area",
                "scheduled_time": "09:00",
                "is_critical": True,
                "is_completed": False,
                "task_date": today,
            },
            {
                "user_id": user_id,
                "grow_id": grow_id,
                "title": "Burp curing jars",
                "description": "Open jars for 10-15 minutes to exchange air",
                "scheduled_time": "12:00",
                "is_critical": False,
                "is_completed": False,
                "task_date": today,
            },
        ]

    return base_tasks


async def check_sensor_anomalies():
    """
    Check recent sensor readings for anomalies across all active grows.
    Runs every 6 hours.
    """
    logger.info("🔍 [CRON] Starting sensor anomaly check...")
    sb = get_supabase_client()

    try:
        from app.services.alert_service import AlertService
        from datetime import timedelta

        # Get readings from the last 6 hours
        since = (datetime.utcnow() - timedelta(hours=6)).isoformat()

        result = sb.table("sensor_readings").select(
            "*, grows!sensor_readings_grow_id_fkey(user_id, strain_name)"
        ).gte("created_at", since).execute()

        if not result.data:
            logger.info("   No recent sensor readings found.")
            return

        logger.info("   Checking %d readings for anomalies...", len(result.data))
        alerts_created = 0

        for reading in result.data:
            grow_info = reading.pop("grows", {}) or {}
            user_id = grow_info.get("user_id")

            if not user_id:
                continue

            alerts = await AlertService.check_sensor_reading(
                grow_id=reading["grow_id"],
                user_id=user_id,
                reading=reading,
            )

            if alerts:
                alerts_created += len(alerts)

        logger.info(
            "✅ [CRON] Anomaly check complete: %d alerts from %d readings",
            alerts_created, len(result.data),
        )

    except Exception as e:
        logger.error("❌ [CRON] Anomaly check failed: %s", e)


async def weekly_xp_reconciliation():
    """
    Reconcile all user levels and award weekly bonuses based on activity.
    Runs every Sunday at 00:00 UTC.
    """
    logger.info("📊 [CRON] Starting weekly XP reconciliation...")
    sb = get_supabase_client()

    try:
        from app.services.gamification_service import (
            award_weekly_bonuses, reconcile_all_levels
        )
        
        # 1. Award bonuses based on this week's activity
        await award_weekly_bonuses(sb)
        
        # 2. Ensure all levels are correctly synchronized with total XP
        await reconcile_all_levels(sb)
        
        logger.info("✅ [CRON] Weekly XP reconciliation complete")

    except Exception as e:
        logger.error("❌ [CRON] Weekly XP reconciliation failed: %s", e)


# ── Scheduler Setup ───────────────────────────────────────────

scheduler = AsyncIOScheduler(timezone="UTC")


def _job_listener(event):
    """Log job execution results."""
    if event.exception:
        logger.error(
            "❌ Job %s failed: %s", event.job_id, event.exception
        )
    else:
        logger.info(
            "✅ Job %s completed successfully (retval=%s)",
            event.job_id, event.retval,
        )


def setup_scheduler():
    """Configure and register all scheduled jobs."""
    # Job 1: Generate daily tasks at 00:00 UTC
    scheduler.add_job(
        generate_all_daily_tasks,
        trigger=CronTrigger(hour=0, minute=0),
        id="daily_tasks_generator",
        name="Daily Tasks Generator",
        replace_existing=True,
        misfire_grace_time=3600,  # Allow up to 1 hour late
    )

    # Job 2: Check sensor anomalies every 6 hours
    scheduler.add_job(
        check_sensor_anomalies,
        trigger=CronTrigger(hour="0,6,12,18", minute=0),
        id="anomaly_checker",
        name="Sensor Anomaly Checker",
        replace_existing=True,
        misfire_grace_time=1800,  # Allow up to 30 min late
    )

    # Job 3: Weekly XP reconciliation (Sunday 00:00 UTC)
    scheduler.add_job(
        weekly_xp_reconciliation,
        trigger=CronTrigger(day_of_week="sun", hour=0, minute=0),
        id="weekly_xp_reconciler",
        name="Weekly XP Reconciler",
        replace_existing=True,
        misfire_grace_time=86400,  # Allow up to 1 day late
    )

    # Listen for job events
    scheduler.add_listener(_job_listener, EVENT_JOB_EXECUTED | EVENT_JOB_ERROR)

    logger.info("📅 Scheduler configured with %d jobs:", len(scheduler.get_jobs()))
    for job in scheduler.get_jobs():
        logger.info("   • %s (%s) → next run: %s", job.name, job.id, job.next_run_time)


def start_scheduler():
    """Start the scheduler (call from FastAPI startup)."""
    setup_scheduler()
    scheduler.start()
    logger.info("🚀 Scheduler started")


def stop_scheduler():
    """Gracefully shut down the scheduler (call from FastAPI shutdown)."""
    if scheduler.running:
        scheduler.shutdown(wait=False)
        logger.info("🛑 Scheduler stopped")
