"""
Aurora Proactive Analysis Service
Runs as a cron job every 24 hours. Reads grow_snapshots,
compares against AI plan optimal ranges, and generates
proactive Dr. Aurora messages when anomalies are detected.
"""
import asyncio
import logging
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional
from uuid import uuid4

from groq import Groq
from supabase import Client
from tenacity import retry, stop_after_attempt, wait_exponential

logger = logging.getLogger(__name__)

MODEL = "llama-3.1-8b-instant"
MAX_TOKENS = 1024
TEMPERATURE = 0.5


class ProactiveAnalysisService:
    """
    Analyzes user grows proactively, comparing recent sensor data
    against optimal ranges and generating Dr. Aurora alerts.
    """

    def __init__(self, groq_client: Groq, supabase_client: Client):
        self.groq = groq_client
        self.supabase = supabase_client

    async def run_analysis(self) -> Dict[str, Any]:
        """
        Main entry point. Scans all active grows and checks for anomalies.
        Returns a summary dict with counts.
        """
        processed = 0
        alerts_sent = 0
        errors = 0

        # 1. Get all active grows
        active_grows = await self._get_active_grows()
        logger.info("Found %d active grows to analyze", len(active_grows))

        for grow in active_grows:
            try:
                grow_id = grow["id"]
                user_id = grow["user_id"]

                # 2. Get latest snapshot
                snapshot = await self._get_latest_snapshot(grow_id)
                if not snapshot:
                    logger.debug("No snapshot for grow %s, skipping", grow_id)
                    continue

                # 3. Extract optimal ranges from AI plan
                optimal = self._extract_optimal_ranges(grow)
                if not optimal:
                    logger.debug("No AI plan for grow %s, skipping", grow_id)
                    continue

                # 4. Compare and detect anomalies
                anomalies = self._detect_anomalies(snapshot, optimal)

                if anomalies:
                    # 5. Generate proactive message
                    message = await self._generate_proactive_message(
                        grow, snapshot, optimal, anomalies,
                    )

                    # 6. Save as system chat message
                    await self._save_system_message(user_id, message)

                    # 7. Create notification
                    await self._create_notification(
                        user_id, grow, anomalies, message,
                    )

                    alerts_sent += 1
                    logger.info(
                        "Proactive alert for grow %s: %d anomalies",
                        grow_id, len(anomalies),
                    )

                processed += 1

            except Exception as e:
                logger.error("Error analyzing grow %s: %s", grow.get("id"), e)
                errors += 1

        summary = {
            "processed": processed,
            "alerts_sent": alerts_sent,
            "errors": errors,
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
        logger.info("Proactive analysis complete: %s", summary)
        return summary

    # ------------------------------------------------------------------
    # Data loading
    # ------------------------------------------------------------------

    async def _get_active_grows(self) -> List[Dict[str, Any]]:
        """Fetch all active grows with their AI plans."""
        try:
            result = await asyncio.to_thread(
                lambda: self.supabase.table("grows")
                .select(
                    "id, user_id, name, strain_name, current_phase, "
                    "medium, light_type, light_wattage, ai_plan, start_date"
                )
                .eq("status", "active")
                .execute()
            )
            return result.data or []
        except Exception as e:
            logger.error("Failed to fetch active grows: %s", e)
            return []

    async def _get_latest_snapshot(
        self, grow_id: str,
    ) -> Optional[Dict[str, Any]]:
        """Get the most recent grow snapshot."""
        try:
            result = await asyncio.to_thread(
                lambda: self.supabase.table("grow_snapshots")
                .select("*")
                .eq("grow_id", grow_id)
                .order("recorded_at", desc=True)
                .limit(1)
                .execute()
            )
            return result.data[0] if result.data else None
        except Exception as e:
            logger.warning("Failed to get snapshot for grow %s: %s", grow_id, e)
            return None

    # ------------------------------------------------------------------
    # Range extraction & comparison
    # ------------------------------------------------------------------

    def _extract_optimal_ranges(
        self, grow: Dict[str, Any],
    ) -> Optional[Dict[str, Any]]:
        """Extract optimal environmental ranges from the grow's AI plan."""
        ai_plan = grow.get("ai_plan")
        if not ai_plan or not isinstance(ai_plan, dict):
            return None

        current_phase = grow.get("current_phase", "vegetative")
        phases = ai_plan.get("phases", [])

        for phase_data in phases:
            if phase_data.get("phase") == current_phase:
                env = phase_data.get("environment", {})
                nutr = phase_data.get("nutrients", {})
                return {
                    "temp_day_min": env.get("temperature_day_c", 24) - 3,
                    "temp_day_max": env.get("temperature_day_c", 26) + 3,
                    "temp_night_min": env.get("temperature_night_c", 18) - 3,
                    "temp_night_max": env.get("temperature_night_c", 22) + 3,
                    "humidity_min": max(20, env.get("humidity_percent", 60) - 15),
                    "humidity_max": min(90, env.get("humidity_percent", 60) + 15),
                    "vpd_min": env.get("vpd_min", 0.8),
                    "vpd_max": env.get("vpd_max", 1.2),
                    "ph_min": nutr.get("ph_min", 5.8),
                    "ph_max": nutr.get("ph_max", 6.5),
                    "ec_min": nutr.get("ec_min", 0.8),
                    "ec_max": nutr.get("ec_max", 2.0),
                }

        return None

    def _detect_anomalies(
        self,
        snapshot: Dict[str, Any],
        optimal: Dict[str, Any],
    ) -> List[Dict[str, Any]]:
        """Compare snapshot values against optimal ranges."""
        anomalies: List[Dict[str, Any]] = []

        checks = [
            ("temperature", "temp_day_min", "temp_day_max", "Temperature", "°C"),
            ("humidity", "humidity_min", "humidity_max", "Humidity", "%"),
            ("vpd", "vpd_min", "vpd_max", "VPD", "kPa"),
            ("ph", "ph_min", "ph_max", "pH", ""),
            ("ec", "ec_min", "ec_max", "EC", "mS/cm"),
        ]

        for field, min_key, max_key, label, unit in checks:
            value = snapshot.get(field)
            if value is None:
                continue

            value = float(value)
            range_min = float(optimal.get(min_key, 0))
            range_max = float(optimal.get(max_key, 999))

            if value < range_min:
                severity = "critical" if value < range_min * 0.8 else "warning"
                anomalies.append({
                    "parameter": label,
                    "current": value,
                    "expected_min": range_min,
                    "expected_max": range_max,
                    "unit": unit,
                    "direction": "low",
                    "severity": severity,
                })
            elif value > range_max:
                severity = "critical" if value > range_max * 1.2 else "warning"
                anomalies.append({
                    "parameter": label,
                    "current": value,
                    "expected_min": range_min,
                    "expected_max": range_max,
                    "unit": unit,
                    "direction": "high",
                    "severity": severity,
                })

        return anomalies

    # ------------------------------------------------------------------
    # Message generation
    # ------------------------------------------------------------------

    async def _generate_proactive_message(
        self,
        grow: Dict[str, Any],
        snapshot: Dict[str, Any],
        optimal: Dict[str, Any],
        anomalies: List[Dict[str, Any]],
    ) -> str:
        """Use Groq to generate a helpful proactive alert message."""
        anomaly_desc = "\n".join(
            f"- {a['parameter']}: current {a['current']}{a['unit']} "
            f"({'too low' if a['direction'] == 'low' else 'too high'}, "
            f"optimal range: {a['expected_min']}-{a['expected_max']}{a['unit']}, "
            f"severity: {a['severity']})"
            for a in anomalies
        )

        prompt = (
            f"You are Dr. Aurora, a cannabis cultivation AI doctor.\n"
            f"Generate a concise, actionable proactive alert for a grower.\n\n"
            f"Grow: {grow.get('name', 'Unknown')}\n"
            f"Strain: {grow.get('strain_name', 'Unknown')}\n"
            f"Phase: {grow.get('current_phase', 'Unknown')}\n"
            f"Medium: {grow.get('medium', 'Unknown')}\n\n"
            f"Anomalies detected:\n{anomaly_desc}\n\n"
            f"Write a warm but urgent message that:\n"
            f"1. Lists what's wrong\n"
            f"2. Explains the potential impact on the plants\n"
            f"3. Gives 2-3 specific corrective actions\n"
            f"4. Ends with encouragement\n\n"
            f"Keep it under 200 words. Use emoji sparingly."
        )

        messages = [
            {"role": "system", "content": "You are Dr. Aurora, a cannabis cultivation expert. Be concise and actionable."},
            {"role": "user", "content": prompt},
        ]

        return await asyncio.to_thread(
            self._call_groq_with_retry, messages,
        )

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
    )
    def _call_groq_with_retry(
        self, messages: List[Dict[str, str]],
    ) -> str:
        """Synchronous Groq call with retry. Runs in asyncio.to_thread."""
        response = self.groq.chat.completions.create(
            model=MODEL,
            messages=messages,
            temperature=TEMPERATURE,
            max_tokens=MAX_TOKENS,
        )
        return response.choices[0].message.content

    # ------------------------------------------------------------------
    # Persistence
    # ------------------------------------------------------------------

    async def _save_system_message(
        self, user_id: str, content: str,
    ) -> None:
        """Save a proactive message as a system chat message."""
        try:
            await asyncio.to_thread(
                lambda: self.supabase.table("chat_messages")
                .insert({
                    "id": str(uuid4()),
                    "user_id": user_id,
                    "role": "system",
                    "content": content,
                    "metadata": {
                        "type": "proactive_analysis",
                        "generated_at": datetime.now(timezone.utc).isoformat(),
                    },
                })
                .execute()
            )
        except Exception as e:
            logger.error("Failed to save system message: %s", e)

    async def _create_notification(
        self,
        user_id: str,
        grow: Dict[str, Any],
        anomalies: List[Dict[str, Any]],
        message: str,
    ) -> None:
        """Create a notification for the anomaly alert."""
        try:
            severity_list = [a["severity"] for a in anomalies]
            is_critical = "critical" in severity_list
            params = ", ".join(a["parameter"] for a in anomalies)

            title = (
                "🚨 Critical Alert" if is_critical
                else "⚠️ Environment Alert"
            ) + f" — {grow.get('name', 'Grow')}"

            body = (
                f"{params} out of optimal range. "
                f"Check Dr. Aurora chat for details."
            )

            await asyncio.to_thread(
                lambda: self.supabase.table("notifications")
                .insert({
                    "user_id": user_id,
                    "type": "alert",
                    "title": title,
                    "body": body,
                    "data": {
                        "type": "proactive_alert",
                        "grow_id": grow.get("id"),
                        "anomalies": anomalies,
                    },
                    "is_read": False,
                })
                .execute()
            )

            # Placeholder: In production, send actual push notification
            # via Firebase Cloud Messaging using the user's
            # notification_token from the profiles table.

        except Exception as e:
            logger.error("Failed to create proactive notification: %s", e)
