"""
Aurora Backend - Pydantic Models
Schemas for API requests and responses.
"""
from pydantic import BaseModel, Field, field_validator
from typing import Optional, List
from datetime import date
from enum import Enum


class SeedType(str, Enum):
    """Seed type enumeration."""
    REGULAR = "regular"
    FEMINIZED = "feminized"
    AUTO = "auto"


class GrowMedium(str, Enum):
    """Growing medium enumeration."""
    SOIL = "soil"
    COCO = "coco"
    HYDRO = "hydro"
    AERO = "aero"


class ExperienceLevel(str, Enum):
    """Grower experience level."""
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"


class GrowPhase(str, Enum):
    """Growth phase enumeration."""
    GERMINATION = "germination"
    SEEDLING = "seedling"
    VEGETATIVE = "vegetative"
    FLOWERING = "flowering"
    HARVEST = "harvest"
    DRYING = "drying"
    CURING = "curing"


# ============================================
# Request Models
# ============================================

class GrowPlanRequest(BaseModel):
    """Request model for generating a grow plan."""
    
    strain_name: str = Field(
        ..., 
        min_length=1, 
        max_length=100,
        description="Name of the cannabis strain"
    )
    seed_type: SeedType = Field(
        default=SeedType.FEMINIZED,
        description="Type of seed (regular, feminized, auto)"
    )
    medium: GrowMedium = Field(
        default=GrowMedium.SOIL,
        description="Growing medium"
    )
    light_type: str = Field(
        default="LED",
        max_length=50,
        description="Type of lighting (LED, HPS, CMH, CFL)"
    )
    light_wattage: int = Field(
        default=300,
        ge=50,
        le=2000,
        description="Light wattage"
    )
    space_width_cm: int = Field(
        default=60,
        ge=30,
        le=500,
        description="Grow space width in centimeters"
    )
    space_length_cm: int = Field(
        default=60,
        ge=30,
        le=500,
        description="Grow space length in centimeters"
    )
    space_height_cm: int = Field(
        default=150,
        ge=60,
        le=300,
        description="Grow space height in centimeters"
    )
    start_date: date = Field(
        default_factory=date.today,
        description="Planned start date for the grow"
    )
    experience_level: ExperienceLevel = Field(
        default=ExperienceLevel.BEGINNER,
        description="Grower's experience level"
    )
    
    @field_validator('strain_name')
    @classmethod
    def validate_strain_name(cls, v: str) -> str:
        """Clean and validate strain name."""
        return v.strip().title()


# ============================================
# Response Models - Nested Structures
# ============================================

class EnvironmentParams(BaseModel):
    """Environmental parameters for a growth phase."""
    temperature_day_c: int = Field(..., description="Daytime temperature in Celsius")
    temperature_night_c: int = Field(..., description="Nighttime temperature in Celsius")
    humidity_percent: int = Field(..., description="Target humidity percentage")
    vpd_min: float = Field(..., description="Minimum VPD in kPa")
    vpd_max: float = Field(..., description="Maximum VPD in kPa")
    light_hours: int = Field(..., description="Hours of light per day")
    co2_ppm: Optional[int] = Field(default=None, description="CO2 level in PPM")


class NutrientSchedule(BaseModel):
    """Nutrient schedule for a growth phase."""
    nitrogen_level: str = Field(..., description="Nitrogen level (low/medium/high)")
    phosphorus_level: str = Field(..., description="Phosphorus level (low/medium/high)")
    potassium_level: str = Field(..., description="Potassium level (low/medium/high)")
    ec_min: float = Field(..., description="Minimum EC value")
    ec_max: float = Field(..., description="Maximum EC value")
    ph_min: float = Field(..., description="Minimum pH value")
    ph_max: float = Field(..., description="Maximum pH value")
    feeding_frequency: str = Field(..., description="Feeding frequency description")
    additives: List[str] = Field(default_factory=list, description="Recommended additives")


class WeeklyTask(BaseModel):
    """A task to be completed during a specific week."""
    day: int = Field(..., ge=1, le=7, description="Day of the week (1-7)")
    task_type: str = Field(..., description="Type of task (watering, feeding, training, etc.)")
    title: str = Field(..., description="Task title")
    description: str = Field(..., description="Detailed task description")
    is_critical: bool = Field(default=False, description="Whether this task is critical")


class PhaseWeek(BaseModel):
    """A week within a growth phase."""
    week_number: int = Field(..., description="Week number within the phase")
    focus: str = Field(..., description="Main focus for this week")
    tasks: List[WeeklyTask] = Field(default_factory=list, description="Tasks for this week")
    tips: List[str] = Field(default_factory=list, description="Tips for this week")


class GrowPlanPhase(BaseModel):
    """A complete phase in the grow plan."""
    phase: GrowPhase = Field(..., description="Growth phase type")
    name: str = Field(..., description="Phase display name")
    duration_days: int = Field(..., description="Duration in days")
    start_day: int = Field(..., description="Start day from grow start")
    end_day: int = Field(..., description="End day from grow start")
    description: str = Field(..., description="Phase description")
    environment: EnvironmentParams = Field(..., description="Environmental parameters")
    nutrients: NutrientSchedule = Field(..., description="Nutrient schedule")
    weeks: List[PhaseWeek] = Field(default_factory=list, description="Weekly breakdown")
    key_milestones: List[str] = Field(default_factory=list, description="Key milestones to watch for")
    common_issues: List[str] = Field(default_factory=list, description="Common issues to avoid")


class GrowPlanSummary(BaseModel):
    """Summary overview of the grow plan."""
    total_duration_days: int = Field(..., description="Total estimated grow duration")
    estimated_yield_grams_min: int = Field(..., description="Minimum estimated yield in grams")
    estimated_yield_grams_max: int = Field(..., description="Maximum estimated yield in grams")
    difficulty_rating: int = Field(..., ge=1, le=5, description="Difficulty rating 1-5")
    key_success_factors: List[str] = Field(..., description="Key factors for success")
    strain_specific_tips: List[str] = Field(..., description="Strain-specific growing tips")


# ============================================
# Main Response Model
# ============================================

class GrowPlanResponse(BaseModel):
    """Complete grow plan response."""
    id: Optional[str] = Field(default=None, description="Plan ID after saving")
    strain_name: str = Field(..., description="Strain name")
    seed_type: SeedType = Field(..., description="Seed type")
    medium: GrowMedium = Field(..., description="Growing medium")
    start_date: date = Field(..., description="Start date")
    summary: GrowPlanSummary = Field(..., description="Plan summary")
    phases: List[GrowPlanPhase] = Field(..., description="All growth phases")
    generated_at: str = Field(..., description="Generation timestamp")


class GeneratePlanResponse(BaseModel):
    """API response wrapper for plan generation."""
    success: bool = Field(..., description="Whether generation was successful")
    message: str = Field(..., description="Response message")
    plan: Optional[GrowPlanResponse] = Field(default=None, description="Generated plan")
    grow_id: Optional[str] = Field(default=None, description="Saved grow ID in database")


# ============================================
# Error Models
# ============================================

class ErrorResponse(BaseModel):
    """Standard error response."""
    success: bool = Field(default=False)
    error: str = Field(..., description="Error message")
    code: str = Field(..., description="Error code")
    details: Optional[dict] = Field(default=None, description="Additional error details")


class RateLimitError(BaseModel):
    """Rate limit error response."""
    success: bool = Field(default=False)
    error: str = Field(default="Rate limit exceeded")
    retry_after_seconds: int = Field(..., description="Seconds to wait before retrying")
