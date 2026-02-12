"""
📁 backend/app/routers/sensors.py
Sensors router — endpoints for sensor data ingestion and retrieval.
"""

import asyncio
import logging
from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field

from app.dependencies import get_supabase_client, get_current_user_id
from app.services.alert_service import AlertService

logger = logging.getLogger("aurora.sensors")

router = APIRouter(prefix="/sensors", tags=["Sensors"])


# ── Pydantic Models ─────────────────────────────────────────────

class SensorReading(BaseModel):
    grow_id: str
    temperature: Optional[float] = None
    humidity: Optional[float] = None
    ph: Optional[float] = None
    ec: Optional[float] = None
    light_intensity: Optional[float] = None
    co2_ppm: Optional[float] = None
    soil_moisture: Optional[float] = None


# ── Submit Reading ──────────────────────────────────────────────

@router.post("/readings", status_code=status.HTTP_201_CREATED)
async def submit_reading(
    body: SensorReading,
    user_id: str = Depends(get_current_user_id),
):
    """Submit a new sensor reading. Triggers alert checks for out-of-range values."""
    sb = get_supabase_client()

    try:
        reading_data = body.model_dump(exclude_none=True)
        reading_data["user_id"] = user_id

        # Calculate VPD if temperature and humidity are present
        if body.temperature is not None and body.humidity is not None:
            vpd = await AlertService.calculate_vpd(body.temperature, body.humidity)
            reading_data["vpd"] = vpd

        # Save reading
        result = await asyncio.to_thread(
            sb.table("sensor_readings").insert(reading_data).execute
        )

        # Check for alerts in background
        alerts = await AlertService.check_sensor_reading(
            grow_id=body.grow_id,
            user_id=user_id,
            reading=reading_data,
        )

        return {
            "reading": result.data[0] if result.data else reading_data,
            "alerts": alerts,
        }

    except Exception as e:
        logger.error("Submit reading error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})


# ── Get Latest Readings ────────────────────────────────────────

@router.get("/latest/{grow_id}")
async def get_latest_readings(
    grow_id: str,
    user_id: str = Depends(get_current_user_id),
):
    """Get the most recent sensor readings for a grow."""
    sb = get_supabase_client()

    try:
        result = await asyncio.to_thread(
            sb.table("sensor_readings")
            .select("*")
            .eq("grow_id", grow_id)
            .order("created_at", desc=True)
            .limit(1)
            .execute
        )

        if not result.data:
            return {"reading": None}

        return {"reading": result.data[0]}

    except Exception as e:
        logger.error("Get latest readings error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})


# ── Get History ─────────────────────────────────────────────────

@router.get("/history/{grow_id}")
async def get_sensor_history(
    grow_id: str,
    hours: int = Query(24, ge=1, le=168),
    user_id: str = Depends(get_current_user_id),
):
    """Get sensor reading history for a grow over the specified hours."""
    sb = get_supabase_client()

    try:
        from datetime import timedelta
        since = (datetime.utcnow() - timedelta(hours=hours)).isoformat()

        result = await asyncio.to_thread(
            sb.table("sensor_readings")
            .select("*")
            .eq("grow_id", grow_id)
            .gte("created_at", since)
            .order("created_at", desc=False)
            .execute
        )

        return {"readings": result.data, "hours": hours}

    except Exception as e:
        logger.error("Get sensor history error: %s", e)
        raise HTTPException(500, detail={"error": str(e)})


# ── Get Alerts ──────────────────────────────────────────────────

@router.get("/alerts")
async def get_my_alerts(
    user_id: str = Depends(get_current_user_id),
):
    """Get unread alerts for the current user."""
    alerts = await AlertService.get_unread_alerts(user_id)
    return {"alerts": alerts}


@router.patch("/alerts/{alert_id}/read")
async def mark_alert_read(
    alert_id: str,
    user_id: str = Depends(get_current_user_id),
):
    """Mark an alert as read."""
    success = await AlertService.mark_alert_read(alert_id, user_id)
    if not success:
        raise HTTPException(500, detail={"error": "Failed to mark alert as read"})
    return {"marked_read": True}
