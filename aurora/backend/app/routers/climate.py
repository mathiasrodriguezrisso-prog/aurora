"""
📁 backend/app/routers/climate.py
Climate & Environment Endpoints — VPD, temperature, humidity guidance
"""

import logging
from typing import Optional

from fastapi import APIRouter, Query, HTTPException, status
from pydantic import BaseModel, Field

from app.utils.vpd import vpd_kpa, saturation_vapor_pressure_kpa, actual_vapor_pressure_kpa

logger = logging.getLogger("aurora.climate")

router = APIRouter(prefix="/climate", tags=["Climate"])

# ── Pydantic Models ─────────────────────────────────────────────

class VPDRequest(BaseModel):
    """Request for VPD calculation."""
    temp: float = Field(..., ge=-50, le=50, description="Temperature in °C (-50 to 50)")
    humidity: float = Field(..., ge=0, le=100, description="Relative humidity in % (0-100)")


class VPDResponse(BaseModel):
    """VPD calculation response with growth stage recommendations."""
    temperature_c: float
    relative_humidity_percent: float
    vpd_kpa: float
    saturation_vapor_pressure_kpa: float
    actual_vapor_pressure_kpa: float
    growth_stage_optimal: Optional[str] = None
    growth_stage_acceptable: Optional[str] = None
    recommendations: list[str] = Field(default_factory=list)
    warning: Optional[str] = None


class VPDHistoricalData(BaseModel):
    """Historical VPD data point."""
    timestamp: str
    temperature_c: float
    humidity_percent: float
    vpd_kpa: float


# ── VPD Endpoint ────────────────────────────────────────────────

@router.get("/vpd", response_model=VPDResponse, status_code=status.HTTP_200_OK)
async def get_vpd(
    temp: float = Query(..., ge=-50, le=50, description="Temperature in °C"),
    humidity: float = Query(..., ge=0, le=100, description="Relative humidity in %"),
):
    """
    Calculate Vapor Pressure Deficit (VPD) for current climate conditions.

    VPD is crucial for cannabis cultivation:
    - Helps optimize plant transpiration
    - Influences nutrient uptake
    - Affects growth rate and bud development

    **Units:**
    - Temperature: Celsius (°C)
    - Humidity: Percentage (%)
    - VPD: kilopascals (kPa)

    **Optimal Ranges by Growth Stage:**
    - Seedling (0-2 weeks): 0.5-1.0 kPa
    - Vegetative (2-8 weeks): 1.0-1.3 kPa
    - Early Flower (0-2 weeks): 1.2-1.5 kPa
    - Peak Flower (2-6 weeks): 1.0-1.5 kPa
    - Late Flower (6-8 weeks): 0.8-1.2 kPa
    """
    try:
        # Calculate VPD and components
        vpd = vpd_kpa(temp, humidity)
        es = saturation_vapor_pressure_kpa(temp)
        ea = actual_vapor_pressure_kpa(temp, humidity)

        # Determine growth stage recommendations
        growth_stage, acceptable_stages, recommendations = _get_vpd_recommendations(vpd, temp, humidity)

        # Check for warnings
        warning = _check_vpd_warnings(vpd, temp, humidity)

        return VPDResponse(
            temperature_c=temp,
            relative_humidity_percent=humidity,
            vpd_kpa=round(vpd, 3),
            saturation_vapor_pressure_kpa=round(es, 3),
            actual_vapor_pressure_kpa=round(ea, 3),
            growth_stage_optimal=growth_stage,
            growth_stage_acceptable=acceptable_stages,
            recommendations=recommendations,
            warning=warning
        )

    except Exception as e:
        logger.error("VPD calculation error: %s", e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": "VPD calculation failed",
                "detail": "An unexpected error occurred",
                "code": "CLIMATE_VPD_ERROR"
            }
        )


# ── Helper Functions ────────────────────────────────────────────

def _get_vpd_recommendations(vpd: float, temp: float, humidity: float) -> tuple[Optional[str], Optional[str], list[str]]:
    """
    Get growth stage recommendations based on VPD.

    Returns: (optimal_stage, acceptable_stages, recommendations)
    """
    recommendations = []

    # Optimal stage determination
    if vpd < 0.5:
        optimal_stage = "High Humidity Conditions"
        acceptable = "Seedling, Early Propagation"
    elif vpd < 1.0:
        optimal_stage = "Seedling / Early Vegetative"
        acceptable = "Seedling (0-2 weeks)"
    elif vpd < 1.3:
        optimal_stage = "Vegetative Growth"
        acceptable = "Vegetative (2-8 weeks)"
    elif vpd < 1.5:
        optimal_stage = "Early Flowering"
        acceptable = "Early Flower (0-2 weeks), Peak Flower (weeks 2-6)"
    elif vpd < 1.8:
        optimal_stage = "Peak Flowering"
        acceptable = "Peak Flower (2-6 weeks)"
    else:
        optimal_stage = "Late Flowering / Stress"
        acceptable = "Late Flower (6-8 weeks)"

    # Generate recommendations
    if vpd < 0.4:
        recommendations.append("VPD is very low - increase air circulation or lower humidity")
        recommendations.append("Consider adding a small fan or reducing watering frequency")
        recommendations.append("Watch for fungal issues due to high humidity")

    elif vpd < 0.8:
        recommendations.append("VPD is good for seedlings and early propagation")
        recommendations.append("Maintain current conditions or adjust gradually if transitioning")

    elif vpd < 1.2:
        recommendations.append("VPD is ideal for vegetative growth")
        recommendations.append("Plants should show strong transpiration")
        recommendations.append("Maintain consistent light and ventilation")

    elif vpd < 1.5:
        recommendations.append("VPD is optimal for flowering")
        recommendations.append("Focus on maintaining stable temperature and humidity")
        recommendations.append("Ensure adequate CO2 levels for photosynthesis")

    elif vpd < 1.8:
        recommendations.append("VPD is high but acceptable for peak flowering")
        recommendations.append("Monitor plants for stress (wilting, discoloration)")
        recommendations.append("Ensure sufficient water availability")

    else:
        recommendations.append("⚠️  VPD is very high - plants may be stressed")
        recommendations.append("Increase humidity by reducing temperature or adding moisture")
        recommendations.append("Improve air circulation to prevent localized dry pockets")
        recommendations.append("Monitor for calcium and magnesium deficiencies")

    # Temperature recommendations
    if temp < 15:
        recommendations.append("Temperature is cold - consider heating, growth will be slow")
    elif temp > 32:
        recommendations.append("Temperature is high - improve ventilation and cooling")

    # Humidity recommendations
    if humidity < 20:
        recommendations.append("Humidity is very low - increase moisture to prevent drying")
    elif humidity > 80:
        recommendations.append("Humidity is high - ensure good air circulation to prevent mold")

    return optimal_stage, acceptable, recommendations


def _check_vpd_warnings(vpd: float, temp: float, humidity: float) -> Optional[str]:
    """Check for climate warnings."""
    if vpd > 2.0:
        return "Very high VPD - plants may be experiencing severe leaf transpiration stress"
    elif vpd < 0.3:
        return "Very low VPD - risk of fungal diseases due to excessive moisture"
    elif temp > 35:
        return "Temperature is critically high - immediate cooling action needed"
    elif temp < 10:
        return "Temperature is critically low - growth has virtually stopped"
    elif humidity > 90:
        return "Critical humidity - high risk of mold and powdery mildew"
    elif humidity < 10:
        return "Critical humidity - extreme stress on plants"
    return None


# ── Future Endpoints (Planned) ──────────────────────────────────

# GET /climate/recommendation - Get climate recommendations for specific phase
# GET /climate/history - Historical VPD data for grow cycle
# POST /climate/alert - Set alerts for VPD thresholds
# GET /climate/optimal-settings - Suggest optimal temp/humidity combinations


if __name__ == "__main__":
    # Demo VPD calculations
    test_cases = [
        (20.0, 50.0),  # Cool, moderate humidity
        (25.0, 60.0),  # Warm, moderate humidity
        (28.0, 40.0),  # Hot, low humidity
        (15.0, 80.0),  # Cold, high humidity
    ]

    print("VPD Climate Calculations:")
    print("-" * 60)
    for temp, hum in test_cases:
        vpd = vpd_kpa(temp, hum)
        stage, acceptable, _ = _get_vpd_recommendations(vpd, temp, hum)
        print(f"T={temp:5.1f}°C  RH={hum:5.1f}%  VPD={vpd:6.3f}kPa  Stage: {stage}")
    print("-" * 60)
