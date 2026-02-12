"""
Aurora Proactive Cron Job
Run every 24 hours to analyze active grows and generate
proactive Dr. Aurora messages when anomalies are detected.

Usage:
    python -m scripts.proactive_cron

Or via system cron / scheduler:
    0 6 * * * cd /path/to/aurora/backend && python -m scripts.proactive_cron
"""
import asyncio
import logging
import sys
from datetime import datetime, timezone
from pathlib import Path

# Ensure backend root is on sys.path
_backend_root = str(Path(__file__).resolve().parent.parent)
if _backend_root not in sys.path:
    sys.path.insert(0, _backend_root)

from app.config import settings  # noqa: E402
from app.dependencies import get_supabase_client, get_groq_client  # noqa: E402
from app.services.proactive_analysis_service import (  # noqa: E402
    ProactiveAnalysisService,
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
)
logger = logging.getLogger("proactive_cron")


async def main() -> None:
    """Run the proactive analysis pipeline."""
    start = datetime.now(timezone.utc)
    logger.info("🔬 Starting proactive analysis cron job...")

    try:
        supabase = get_supabase_client()
        groq = get_groq_client()

        service = ProactiveAnalysisService(groq, supabase)
        summary = await service.run_analysis()

        elapsed = (datetime.now(timezone.utc) - start).total_seconds()
        logger.info(
            "✅ Analysis complete in %.1fs — "
            "Processed: %d | Alerts: %d | Errors: %d",
            elapsed,
            summary["processed"],
            summary["alerts_sent"],
            summary["errors"],
        )

    except Exception as e:
        logger.error("❌ Proactive cron failed: %s", e, exc_info=True)
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
