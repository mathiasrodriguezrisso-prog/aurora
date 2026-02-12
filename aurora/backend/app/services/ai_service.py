"""
Aurora AI Service
Groq integration for grow plan generation with JSON mode.
"""
import asyncio
import json
import logging
from datetime import datetime
from typing import Dict, Any

from groq import Groq
from tenacity import retry, stop_after_attempt, wait_exponential

from app.models import (
    GrowPlanRequest,
    GrowPlanResponse,
    GrowPlanPhase,
    GrowPlanSummary,
    EnvironmentParams,
    NutrientSchedule,
    PhaseWeek,
    WeeklyTask,
    GrowPhase,
)

logger = logging.getLogger(__name__)


class AIServiceError(Exception):
    """Custom exception for AI service errors."""


class AIService:
    """Service for AI-powered grow plan generation using Groq."""

    MODEL = "llama-3.1-8b-instant"
    MAX_TOKENS = 8000
    TEMPERATURE = 0.7

    def __init__(self, groq_client: Groq):
        """Initialize AI service with Groq client."""
        self.client = groq_client

    def _build_system_prompt(self) -> str:
        """Build the system prompt for grow plan generation."""
        return """You are Aurora, an expert cannabis cultivation AI assistant. \
Your role is to generate detailed, personalized grow plans based on the \
user's setup and preferences.

IMPORTANT: You MUST respond with valid JSON only. No markdown, no \
explanations, just the JSON object.

The JSON response must follow this exact structure:
{
    "summary": {
        "total_duration_days": <integer>,
        "estimated_yield_grams_min": <integer>,
        "estimated_yield_grams_max": <integer>,
        "difficulty_rating": <1-5>,
        "key_success_factors": ["factor1", "factor2", ...],
        "strain_specific_tips": ["tip1", "tip2", ...]
    },
    "phases": [
        {
            "phase": "<germination|seedling|vegetative|flowering|harvest|drying|curing>",
            "name": "<Display Name>",
            "duration_days": <integer>,
            "start_day": <integer>,
            "end_day": <integer>,
            "description": "<phase description>",
            "environment": {
                "temperature_day_c": <integer>,
                "temperature_night_c": <integer>,
                "humidity_percent": <integer>,
                "vpd_min": <float>,
                "vpd_max": <float>,
                "light_hours": <integer>,
                "co2_ppm": <integer or null>
            },
            "nutrients": {
                "nitrogen_level": "<low|medium|high>",
                "phosphorus_level": "<low|medium|high>",
                "potassium_level": "<low|medium|high>",
                "ec_min": <float>,
                "ec_max": <float>,
                "ph_min": <float>,
                "ph_max": <float>,
                "feeding_frequency": "<description>",
                "additives": ["additive1", ...]
            },
            "weeks": [
                {
                    "week_number": <integer>,
                    "focus": "<main focus>",
                    "tasks": [
                        {
                            "day": <1-7>,
                            "task_type": "<watering|feeding|training|defoliation|photo|note|other>",
                            "title": "<task title>",
                            "description": "<detailed description>",
                            "is_critical": <true|false>
                        }
                    ],
                    "tips": ["tip1", "tip2"]
                }
            ],
            "key_milestones": ["milestone1", ...],
            "common_issues": ["issue1", ...]
        }
    ]
}

Guidelines:
- Tailor the plan to the specific strain, medium, and experience level
- For autoflowers, use 18-20 hours of light throughout
- For photoperiods, use 18/6 for veg and 12/12 for flower
- Adjust complexity based on experience level (simpler for beginners)
- Include realistic yield estimates based on space and lighting
- Provide actionable, specific tasks for each week
- Include common issues specific to the strain/medium combination"""

    def _build_user_prompt(self, request: GrowPlanRequest, context: str) -> str:
        """Build the user prompt with grow parameters and RAG context."""
        return (
            f"Generate a complete grow plan with the following parameters:\n\n"
            f"STRAIN: {request.strain_name}\n"
            f"SEED TYPE: {request.seed_type.value}\n"
            f"GROWING MEDIUM: {request.medium.value}\n"
            f"LIGHTING: {request.light_type} at {request.light_wattage}W\n"
            f"GROW SPACE: {request.space_width_cm}cm x "
            f"{request.space_length_cm}cm x {request.space_height_cm}cm\n"
            f"START DATE: {request.start_date.isoformat()}\n"
            f"EXPERIENCE LEVEL: {request.experience_level.value}\n\n"
            f"KNOWLEDGE BASE CONTEXT:\n{context}\n\n"
            f"Generate a detailed grow plan following the exact JSON structure "
            f"specified. Include all phases from germination through curing. "
            f"Provide specific, actionable tasks for each week."
        )

    async def generate_plan(
        self,
        request: GrowPlanRequest,
        context: str,
    ) -> GrowPlanResponse:
        """
        Generate a grow plan using Groq AI.

        Wraps the synchronous Groq SDK in asyncio.to_thread so the
        FastAPI event loop is never blocked. Retries are applied on the
        synchronous call itself.

        Args:
            request: Grow plan request parameters.
            context: RAG context from knowledge base.

        Returns:
            Complete grow plan response.

        Raises:
            AIServiceError: If generation fails after retries.
        """
        try:
            logger.info("Generating plan for strain: %s", request.strain_name)

            system_prompt = self._build_system_prompt()
            user_prompt = self._build_user_prompt(request, context)

            # The sync Groq call with tenacity retry runs inside a thread
            content = await asyncio.to_thread(
                self._call_groq_with_retry, system_prompt, user_prompt
            )

            logger.debug("Raw AI response length: %d", len(content))

            plan_data = json.loads(content)
            validated_plan = self._validate_and_construct(request, plan_data)

            logger.info(
                "Successfully generated plan with %d phases",
                len(validated_plan.phases),
            )
            return validated_plan

        except json.JSONDecodeError as e:
            logger.error("Failed to parse AI response as JSON: %s", e)
            raise AIServiceError(f"Invalid JSON response from AI: {e}") from e
        except KeyError as e:
            logger.error("Missing required field in AI response: %s", e)
            raise AIServiceError(f"Missing required field: {e}") from e
        except AIServiceError:
            raise
        except Exception as e:
            logger.error("AI generation failed: %s", e)
            raise AIServiceError(f"Plan generation failed: {e}") from e

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
    )
    def _call_groq_with_retry(
        self, system_prompt: str, user_prompt: str
    ) -> str:
        """
        Synchronous Groq call wrapped with tenacity retry.

        This runs inside asyncio.to_thread so it never blocks the
        event loop, while tenacity handles retries correctly on the
        synchronous function.
        """
        response = self.client.chat.completions.create(
            model=self.MODEL,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ],
            temperature=self.TEMPERATURE,
            max_tokens=self.MAX_TOKENS,
            response_format={"type": "json_object"},
        )
        return response.choices[0].message.content

    def _validate_and_construct(
        self,
        request: GrowPlanRequest,
        data: Dict[str, Any],
    ) -> GrowPlanResponse:
        """Validate AI response and construct typed response object."""

        # Parse summary
        summary_data = data.get("summary", {})
        summary = GrowPlanSummary(
            total_duration_days=summary_data.get("total_duration_days", 120),
            estimated_yield_grams_min=summary_data.get(
                "estimated_yield_grams_min", 50
            ),
            estimated_yield_grams_max=summary_data.get(
                "estimated_yield_grams_max", 150
            ),
            difficulty_rating=min(
                5, max(1, summary_data.get("difficulty_rating", 3))
            ),
            key_success_factors=summary_data.get("key_success_factors", []),
            strain_specific_tips=summary_data.get("strain_specific_tips", []),
        )

        # Parse phases
        phases = []
        for phase_data in data.get("phases", []):
            # Parse environment
            env_data = phase_data.get("environment", {})
            environment = EnvironmentParams(
                temperature_day_c=env_data.get("temperature_day_c", 25),
                temperature_night_c=env_data.get("temperature_night_c", 20),
                humidity_percent=env_data.get("humidity_percent", 60),
                vpd_min=env_data.get("vpd_min", 0.8),
                vpd_max=env_data.get("vpd_max", 1.2),
                light_hours=env_data.get("light_hours", 18),
                co2_ppm=env_data.get("co2_ppm"),
            )

            # Parse nutrients
            nutr_data = phase_data.get("nutrients", {})
            nutrients = NutrientSchedule(
                nitrogen_level=nutr_data.get("nitrogen_level", "medium"),
                phosphorus_level=nutr_data.get("phosphorus_level", "medium"),
                potassium_level=nutr_data.get("potassium_level", "medium"),
                ec_min=nutr_data.get("ec_min", 1.0),
                ec_max=nutr_data.get("ec_max", 1.5),
                ph_min=nutr_data.get("ph_min", 6.0),
                ph_max=nutr_data.get("ph_max", 6.5),
                feeding_frequency=nutr_data.get(
                    "feeding_frequency", "Every 2-3 days"
                ),
                additives=nutr_data.get("additives", []),
            )

            # Parse weeks
            weeks = []
            for week_data in phase_data.get("weeks", []):
                tasks = [
                    WeeklyTask(
                        day=task_data.get("day", 1),
                        task_type=task_data.get("task_type", "note"),
                        title=task_data.get("title", "Task"),
                        description=task_data.get("description", ""),
                        is_critical=task_data.get("is_critical", False),
                    )
                    for task_data in week_data.get("tasks", [])
                ]

                weeks.append(
                    PhaseWeek(
                        week_number=week_data.get("week_number", 1),
                        focus=week_data.get("focus", ""),
                        tasks=tasks,
                        tips=week_data.get("tips", []),
                    )
                )

            # Parse phase enum
            phase_str = phase_data.get("phase", "vegetative").lower()
            try:
                phase_enum = GrowPhase(phase_str)
            except ValueError:
                phase_enum = GrowPhase.VEGETATIVE

            phases.append(
                GrowPlanPhase(
                    phase=phase_enum,
                    name=phase_data.get("name", phase_str.title()),
                    duration_days=phase_data.get("duration_days", 14),
                    start_day=phase_data.get("start_day", 1),
                    end_day=phase_data.get("end_day", 14),
                    description=phase_data.get("description", ""),
                    environment=environment,
                    nutrients=nutrients,
                    weeks=weeks,
                    key_milestones=phase_data.get("key_milestones", []),
                    common_issues=phase_data.get("common_issues", []),
                )
            )

        return GrowPlanResponse(
            strain_name=request.strain_name,
            seed_type=request.seed_type,
            medium=request.medium,
            start_date=request.start_date,
            summary=summary,
            phases=phases,
            generated_at=datetime.utcnow().isoformat(),
        )

    async def check_toxicity(self, text: str) -> bool:
        """
        Check if a given text is toxic using Groq.
        Returns True if toxic, False otherwise.
        """
        if not text.strip():
            return False

        try:
            prompt = f"""Analyze the following text for toxicity, hate speech, or harassment:
"{text}"

Respond with valid JSON only:
{{"is_toxic": true/false, "reason": "short explanation"}}"""

            content = await asyncio.to_thread(
                self._call_groq_simple, prompt
            )

            data = json.loads(content)
            return data.get("is_toxic", False)

        except Exception as e:
            logger.error("Toxicity check failed: %s", e)
            return False

    def _call_groq_simple(self, prompt: str) -> str:
        """Simplified sync Groq call for moderation."""
        response = self.client.chat.completions.create(
            model=self.MODEL,
            messages=[
                {"role": "user", "content": prompt},
            ],
            temperature=0.1,  # Low temperature for consistency
            max_tokens=100,
            response_format={"type": "json_object"},
        )
        return response.choices[0].message.content
