"""
📁 backend/app/services/alert_service.py
Alert service — monitors sensor readings and triggers alerts
for out-of-range conditions.
"""

import logging
from datetime import datetime
from typing import Optional

from app.dependencies import get_supabase_client

logger = logging.getLogger("aurora.alerts")


# ── Thresholds ──────────────────────────────────────────────────

THRESHOLDS = {
    "temperature": {"min": 18.0, "max": 30.0, "unit": "°C"},
    "humidity": {"min": 40.0, "max": 70.0, "unit": "%"},
    "ph": {"min": 5.8, "max": 6.8, "unit": ""},
    "vpd": {"min": 0.4, "max": 1.6, "unit": "kPa"},
}


class AlertType:
    SENSOR_HIGH = "sensor_high"
    SENSOR_LOW = "sensor_low"
    SENSOR_CRITICAL = "sensor_critical"
    TASK_OVERDUE = "task_overdue"
    PHASE_TRANSITION = "phase_transition"


# ── Alert Service ───────────────────────────────────────────────

class AlertService:
    """Monitors grow conditions and creates alerts."""

    @staticmethod
    async def check_sensor_reading(
        grow_id: str,
        user_id: str,
        reading: dict,
    ) -> list[dict]:
        """
        Check a sensor reading against thresholds and create alerts
        for any out-of-range values.
        """
        alerts: list[dict] = []

        for param, limits in THRESHOLDS.items():
            value = reading.get(param)
            if value is None:
                continue

            alert = None
            if value < limits["min"]:
                severity = "critical" if value < limits["min"] * 0.8 else "warning"
                alert = {
                    "grow_id": grow_id,
                    "user_id": user_id,
                    "alert_type": AlertType.SENSOR_LOW if severity == "warning" else AlertType.SENSOR_CRITICAL,
                    "severity": severity,
                    "parameter": param,
                    "value": value,
                    "threshold_min": limits["min"],
                    "threshold_max": limits["max"],
                    "message": f"{param.title()} is low: {value}{limits['unit']} (min: {limits['min']}{limits['unit']})",
                    "is_read": False,
                }
            elif value > limits["max"]:
                severity = "critical" if value > limits["max"] * 1.2 else "warning"
                alert = {
                    "grow_id": grow_id,
                    "user_id": user_id,
                    "alert_type": AlertType.SENSOR_HIGH if severity == "warning" else AlertType.SENSOR_CRITICAL,
                    "severity": severity,
                    "parameter": param,
                    "value": value,
                    "threshold_min": limits["min"],
                    "threshold_max": limits["max"],
                    "message": f"{param.title()} is high: {value}{limits['unit']} (max: {limits['max']}{limits['unit']})",
                    "is_read": False,
                }

            if alert:
                alerts.append(alert)

        # Save alerts to database
        if alerts:
            try:
                sb = get_supabase_client()
                sb.table("alerts").insert(alerts).execute()
                logger.info("Created %d alerts for grow %s", len(alerts), grow_id)
            except Exception as e:
                logger.error("Failed to save alerts: %s", e)

            # Send push notification for each alert
            try:
                from app.services.push_service import send_push_notification

                for alert in alerts:
                    await send_push_notification(
                        user_id=user_id,
                        title=f"⚠️ {alert['parameter'].title()} Alert",
                        body=alert["message"],
                        data={"type": "alert", "grow_id": grow_id},
                    )
            except Exception as e:
                logger.error("Failed to send push for alerts: %s", e)

        return alerts

    @staticmethod
    async def get_unread_alerts(user_id: str, limit: int = 20) -> list:
        """Get unread alerts for a user."""
        sb = get_supabase_client()
        try:
            result = (
                sb.table("alerts")
                .select("*")
                .eq("user_id", user_id)
                .eq("is_read", False)
                .order("created_at", desc=True)
                .limit(limit)
                .execute()
            )
            return result.data
        except Exception as e:
            logger.error("Get alerts error: %s", e)
            return []

    @staticmethod
    async def mark_alert_read(alert_id: str, user_id: str) -> bool:
        """Mark an alert as read."""
        sb = get_supabase_client()
        try:
            sb.table("alerts").update({"is_read": True}).eq("id", alert_id).eq("user_id", user_id).execute()
            return True
        except Exception as e:
            logger.error("Mark alert read error: %s", e)
            return False

    @staticmethod
    async def calculate_vpd(temperature: float, humidity: float) -> float:
        """Calculate VPD (Vapor Pressure Deficit) from temperature and humidity."""
        import math
        svp = 0.6108 * math.exp((17.27 * temperature) / (temperature + 237.3))
        vpd = svp * (1 - humidity / 100)
        return round(vpd, 2)
