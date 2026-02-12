"""
📁 backend/scripts/seed_achievements.py
Seed the achievements table with 15 unique achievements.

Usage:
  cd backend
  python -m scripts.seed_achievements
"""

import logging
import os
import sys

from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("seed_achievements")


ACHIEVEMENTS = [
    # ── Getting Started ─────────────────────────────────────
    {
        "name": "First Sprout",
        "description": "Create your first post in the community",
        "icon": "🌱",
        "category": "social",
        "condition": {"metric": "posts_created", "operator": ">=", "threshold": 1},
        "reward_xp": 50,
        "reward_karma": 10,
    },
    {
        "name": "Green Thumb",
        "description": "Complete your first grow cycle from seed to harvest",
        "icon": "🌿",
        "category": "growing",
        "condition": {"metric": "grows_completed", "operator": ">=", "threshold": 1},
        "reward_xp": 200,
        "reward_karma": 50,
    },
    {
        "name": "Task Master",
        "description": "Complete 10 daily tasks",
        "icon": "✅",
        "category": "tasks",
        "condition": {"metric": "tasks_completed", "operator": ">=", "threshold": 10},
        "reward_xp": 80,
        "reward_karma": 15,
    },

    # ── Social ──────────────────────────────────────────────
    {
        "name": "Social Butterfly",
        "description": "Create 25 posts in the community",
        "icon": "🦋",
        "category": "social",
        "condition": {"metric": "posts_created", "operator": ">=", "threshold": 25},
        "reward_xp": 150,
        "reward_karma": 30,
    },
    {
        "name": "Community Pillar",
        "description": "Reach 100 karma points",
        "icon": "🏛️",
        "category": "social",
        "condition": {"metric": "karma", "operator": ">=", "threshold": 100},
        "reward_xp": 200,
        "reward_karma": 25,
    },
    {
        "name": "Influencer",
        "description": "Reach 500 karma points",
        "icon": "⭐",
        "category": "social",
        "condition": {"metric": "karma", "operator": ">=", "threshold": 500},
        "reward_xp": 500,
        "reward_karma": 50,
    },

    # ── Growing ─────────────────────────────────────────────
    {
        "name": "Harvest Moon",
        "description": "Complete 3 grow cycles",
        "icon": "🌕",
        "category": "growing",
        "condition": {"metric": "grows_completed", "operator": ">=", "threshold": 3},
        "reward_xp": 300,
        "reward_karma": 60,
    },
    {
        "name": "Master Grower",
        "description": "Complete 10 grow cycles",
        "icon": "👨‍🌾",
        "category": "growing",
        "condition": {"metric": "grows_completed", "operator": ">=", "threshold": 10},
        "reward_xp": 1000,
        "reward_karma": 200,
    },

    # ── Data & Sensors ──────────────────────────────────────
    {
        "name": "Data Nerd",
        "description": "Submit 50 sensor readings",
        "icon": "📊",
        "category": "data",
        "condition": {"metric": "sensor_readings", "operator": ">=", "threshold": 50},
        "reward_xp": 100,
        "reward_karma": 20,
    },
    {
        "name": "Data Scientist",
        "description": "Submit 500 sensor readings",
        "icon": "🔬",
        "category": "data",
        "condition": {"metric": "sensor_readings", "operator": ">=", "threshold": 500},
        "reward_xp": 300,
        "reward_karma": 50,
    },

    # ── Tasks ───────────────────────────────────────────────
    {
        "name": "Diligent Gardener",
        "description": "Complete 50 daily tasks",
        "icon": "📋",
        "category": "tasks",
        "condition": {"metric": "tasks_completed", "operator": ">=", "threshold": 50},
        "reward_xp": 200,
        "reward_karma": 30,
    },
    {
        "name": "Task Legend",
        "description": "Complete 200 daily tasks",
        "icon": "🏆",
        "category": "tasks",
        "condition": {"metric": "tasks_completed", "operator": ">=", "threshold": 200},
        "reward_xp": 500,
        "reward_karma": 100,
    },

    # ── Level Milestones ────────────────────────────────────
    {
        "name": "Rising Star",
        "description": "Reach level 5",
        "icon": "⬆️",
        "category": "level",
        "condition": {"metric": "level", "operator": ">=", "threshold": 5},
        "reward_xp": 100,
        "reward_karma": 20,
    },
    {
        "name": "Veteran",
        "description": "Reach level 15",
        "icon": "🎖️",
        "category": "level",
        "condition": {"metric": "level", "operator": ">=", "threshold": 15},
        "reward_xp": 300,
        "reward_karma": 50,
    },
    {
        "name": "Cannabis Sage",
        "description": "Reach level 30",
        "icon": "🧙",
        "category": "level",
        "condition": {"metric": "level", "operator": ">=", "threshold": 30},
        "reward_xp": 1000,
        "reward_karma": 200,
    },
]


def main():
    from supabase import create_client

    url = os.getenv("SUPABASE_URL", "")
    key = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")

    if not url or not key:
        logger.error("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set")
        sys.exit(1)

    sb = create_client(url, key)
    logger.info("🚀 Seeding %d achievements...", len(ACHIEVEMENTS))

    inserted = 0
    skipped = 0

    for achievement in ACHIEVEMENTS:
        # Check if already exists
        existing = sb.table("achievements").select(
            "id"
        ).eq("name", achievement["name"]).execute()

        if existing.data:
            logger.info("⏭️  Skipping (exists): %s", achievement["name"])
            skipped += 1
            continue

        # Insert
        sb.table("achievements").insert(achievement).execute()
        logger.info(
            "✅ Inserted: %s %s (+%d XP, +%d Karma)",
            achievement["icon"],
            achievement["name"],
            achievement["reward_xp"],
            achievement["reward_karma"],
        )
        inserted += 1

    logger.info("══════════════════════════════════════")
    logger.info(
        "🎉 Seeding complete: %d inserted, %d skipped",
        inserted, skipped,
    )


if __name__ == "__main__":
    main()
