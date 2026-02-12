"""
Aurora Chat Service — Dr. Aurora Engine
Contextual chatbot with memory, summarization, intent detection,
and emergency handling. All sync Groq/Supabase calls wrapped in
asyncio.to_thread() so the FastAPI event loop is never blocked.
"""
import asyncio
import json
import logging
import re
from datetime import datetime, timezone
from typing import Dict, Any, List, Optional, Tuple, AsyncIterator
from uuid import uuid4

from groq import Groq, AsyncGroq
from supabase import Client
from tenacity import retry, stop_after_attempt, wait_exponential

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
MAX_HISTORY_MESSAGES = 10
SUMMARIZE_EVERY = 10
MODEL = "llama-3.1-8b-instant"
MAX_TOKENS = 4096
TEMPERATURE = 0.7
MAX_CONTEXT_TOKENS = 6000  # token budget for context window

EMERGENCY_KEYWORDS = [
    "dying", "dead", "emergency", "urgent", "help me",
    "plants are dying", "all yellow", "wilting badly",
    "root rot", "mold everywhere", "pest infestation",
    "leaves falling", "brown spots everywhere",
    "overwatered badly", "underwatered dying",
    "nutrient burn severe", "lockout",
    "hermie", "hermaphrodite", "nanners",
    "light burn severe", "heat stress critical",
]

INTENT_PATTERNS: Dict[str, list] = {
    "diagnostics": [
        r"\bdiagn", r"\banaly[sz]", r"\bshow\s+(?:me\s+)?(?:data|stats|chart|graph)",
        r"\bsnapshot", r"\breading",
    ],
    "adjust_plan": [
        r"\badjust\s+plan", r"\bchange\s+(?:the\s+)?plan", r"\bmodify\s+(?:the\s+)?plan",
        r"\breschedule", r"\bupdate\s+(?:the\s+)?plan", r"\bnew\s+plan",
    ],
    "question": [
        r"\bwhat\b", r"\bhow\b", r"\bwhy\b", r"\bwhen\b", r"\bshould\b",
        r"\bcan\s+i\b", r"\bis\s+it\b", r"\?$",
    ],
}


# ---------------------------------------------------------------------------
# Token counting (lightweight fallback when tiktoken unavailable)
# ---------------------------------------------------------------------------
def _count_tokens(text: str) -> int:
    """Approximate token count. Uses tiktoken if available, else heuristic."""
    try:
        import tiktoken
        enc = tiktoken.encoding_for_model("gpt-3.5-turbo")
        return len(enc.encode(text))
    except Exception:
        # Rough heuristic: ~4 chars per token for English
        return max(1, len(text) // 4)


# ---------------------------------------------------------------------------
# Dr. Aurora System Prompt
# ---------------------------------------------------------------------------
DR_AURORA_SYSTEM_PROMPT = """\
You are **Dr. Aurora**, an expert AI cannabis cultivation doctor and companion.

## Your Personality
- Warm, knowledgeable, and reassuring — like a trusted mentor
- You use botanical terminology but explain it simply
- You celebrate user progress and encourage best practices
- You are proactive: if you see potential issues, flag them early
- You respond in the same language the user writes in

## Your Capabilities
- Diagnose plant health issues from descriptions
- Recommend environmental adjustments (temp, humidity, VPD, pH, EC)
- Guide nutrient schedules and feeding strategies
- Advise on training techniques (LST, HST, SCROG, SOG)
- Track grow progress and compare against the AI plan
- Detect emergencies and provide urgent actionable advice

## Response Style
- Keep answers concise but thorough (2-4 paragraphs max for normal queries)
- Use bullet points for actionable steps
- For emergencies: lead with the most critical action immediately
- Include specific numbers (pH 6.0-6.5, EC 1.2-1.8, etc.)
- End with a supportive note or follow-up question when appropriate

## Context Awareness
You will receive the user's current grow context (strain, phase, environment,
recent snapshots). Use this to personalize every response. If data looks
anomalous, proactively mention it.

## Safety
- Never recommend illegal activities
- Always prioritize plant health and safety
- If you're unsure, say so and recommend the user verify
"""


class ChatServiceError(Exception):
    """Custom exception for chat service errors."""


class ChatService:
    """
    Dr. Aurora chat engine with context injection, short-term memory,
    auto-summarization, and intent detection.
    """

    def __init__(self, groq_client: Groq, supabase_client: Client, async_groq: Optional[AsyncGroq] = None):
        self.groq = groq_client
        self.supabase = supabase_client
        self.async_groq = async_groq
        from app.services.rag_service import RAGService
        self.rag_service = RAGService(supabase_client)

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    async def process_message(
        self,
        user_id: str,
        message: str,
        grow_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Process a user message and return Dr. Aurora's response.

        Steps:
        1. Detect intent
        2. Load grow context
        3. Load RAG context (semantic knowledge)
        4. Load chat history (last N messages)
        5. Load any existing summaries
        6. Build prompt with context
        7. Call Groq via asyncio.to_thread
        8. Save both messages to DB
        9. If message count hits threshold → auto-summarize
        10. If emergency → insert notification
        11. Return response
        """
        try:
            # 1. Detect intent
            intent, is_emergency = self._detect_intent(message)
            logger.info(
                "Intent detected: %s | Emergency: %s | User: %s",
                intent, is_emergency, user_id,
            )

            # 2. Load grow context
            context_parts: List[str] = []
            context_sources: List[str] = []
            
            grow_info = None
            if grow_id:
                grow_info = await self._get_grow_info(user_id, grow_id)
            else:
                grow_info = await self._get_active_grow_info(user_id)

            if grow_info:
                grow_ctx = self._format_grow_context(grow_info, grow_info["id"])
                context_parts.append(grow_ctx)
                context_sources.append("active_grow")

            # 3. Load RAG context (semantic knowledge)
            # Search knowledge base for relevant info based on user query
            knowledge_docs = await self.rag_service.search_knowledge(
                query=message,
                match_threshold=0.4,
                match_count=3
            )
            if knowledge_docs:
                rag_ctx = self.rag_service.build_context(knowledge_docs, max_tokens=2000)
                context_parts.append(f"## Relevant Knowledge Base Info\n{rag_ctx}")
                context_sources.append("knowledge_base")

            # 3. Load chat history
            history = await self._load_chat_history(user_id)

            # 4. Load summaries
            summaries = await self._load_summaries(user_id)
            if summaries:
                context_parts.append(f"## Previous Conversation Summary\n{summaries}")
                context_sources.append("chat_summary")

            # 5. Build messages
            system_content = DR_AURORA_SYSTEM_PROMPT
            if context_parts:
                system_content += "\n\n## Current Context\n" + "\n\n".join(context_parts)

            # Token budget management
            system_tokens = _count_tokens(system_content)
            user_tokens = _count_tokens(message)
            budget = MAX_CONTEXT_TOKENS - system_tokens - user_tokens - MAX_TOKENS

            trimmed_history = self._trim_history_to_budget(history, budget)

            messages = [{"role": "system", "content": system_content}]
            for msg in trimmed_history:
                messages.append({
                    "role": msg["role"],
                    "content": msg["content"],
                })
            messages.append({"role": "user", "content": message})

            # 6. Call Groq
            response_text = await asyncio.to_thread(
                self._call_groq_with_retry, messages
            )

            total_tokens = _count_tokens(
                system_content
                + message
                + response_text
                + "".join(m["content"] for m in trimmed_history)
            )

            # 7. Save messages to DB
            user_msg_id = await self._save_message(user_id, "user", message, {
                "intent": intent,
                "is_emergency": is_emergency,
            })
            assistant_msg_id = await self._save_message(
                user_id, "assistant", response_text, {
                    "intent": intent,
                    "tokens_used": total_tokens,
                },
            )

            # 8. Auto-summarize check
            await self._maybe_summarize(user_id)

            # 9. Emergency notification
            if is_emergency:
                await self._create_emergency_notification(
                    user_id, message, response_text,
                )

            return {
                "id": assistant_msg_id,
                "role": "assistant",
                "content": response_text,
                "metadata": {
                    "intent": intent,
                    "is_emergency": is_emergency,
                    "tokens_used": total_tokens,
                    "context_sources": context_sources,
                },
                "created_at": datetime.now(timezone.utc).isoformat(),
            }

        except ChatServiceError:
            raise
        except Exception as e:
            logger.error("Chat processing failed: %s", e)
            raise ChatServiceError(f"Failed to process message: {e}") from e

    async def get_history(
        self,
        user_id: str,
        limit: int = 50,
        offset: int = 0,
    ) -> Dict[str, Any]:
        """Return paginated chat history for a user."""
        try:
            # Get total count
            count_result = await asyncio.to_thread(
                lambda: self.supabase.table("chat_messages")
                .select("id", count="exact")
                .eq("user_id", user_id)
                .execute()
            )
            total = count_result.count or 0

            # Get messages
            result = await asyncio.to_thread(
                lambda: self.supabase.table("chat_messages")
                .select("id, role, content, metadata, created_at")
                .eq("user_id", user_id)
                .order("created_at", desc=False)
                .range(offset, offset + limit - 1)
                .execute()
            )

            messages = []
            for row in (result.data or []):
                messages.append({
                    "id": row["id"],
                    "role": row["role"],
                    "content": row["content"],
                    "metadata": row.get("metadata"),
                    "created_at": row["created_at"],
                })

            return {
                "success": True,
                "messages": messages,
                "has_more": (offset + limit) < total,
                "total_count": total,
            }

        except Exception as e:
            logger.error("Failed to load chat history: %s", e)
            raise ChatServiceError(f"Failed to load history: {e}") from e

    # ------------------------------------------------------------------
    # Intent Detection
    # ------------------------------------------------------------------

    def _detect_intent(self, message: str) -> Tuple[str, bool]:
        """Classify user message intent and check for emergency."""
        lower = message.lower().strip()

        # Emergency check first
        is_emergency = any(kw in lower for kw in EMERGENCY_KEYWORDS)
        if is_emergency:
            return "emergency", True

        # Pattern-based intent
        for intent, patterns in INTENT_PATTERNS.items():
            for pattern in patterns:
                if re.search(pattern, lower):
                    return intent, False

        return "general", False

    # ------------------------------------------------------------------
    # Context Loading
    # ------------------------------------------------------------------

    async def _get_grow_info(
        self, user_id: str, grow_id: str,
    ) -> Optional[dict]:
        """Load specific grow data for the user."""
        try:
            grow_result = await asyncio.to_thread(
                lambda: self.supabase.table("grows")
                .select("*")
                .eq("id", grow_id)
                .eq("user_id", user_id)
                .single()
                .execute()
            )
            return grow_result.data
        except Exception as e:
            logger.warning("Failed to load grow info: %s", e)
            return None

    async def _get_active_grow_info(self, user_id: str) -> Optional[dict]:
        """Load the user's most recent active grow data."""
        try:
            result = await asyncio.to_thread(
                lambda: self.supabase.table("grows")
                .select("*")
                .eq("user_id", user_id)
                .eq("status", "active")
                .order("created_at", desc=True)
                .limit(1)
                .execute()
            )
            if not result.data:
                return None
            return result.data[0]
        except Exception as e:
            logger.warning("Failed to load active grow info: %s", e)
            return None

    def _format_grow_context(self, grow: dict, grow_id: str) -> str:
        """Format grow data + recent snapshots into context string."""
        parts = [
            f"## Active Grow: {grow.get('name', 'Unknown')}",
            f"- **Strain**: {grow.get('strain_name', 'Unknown')}",
            f"- **Medium**: {grow.get('medium', 'Unknown')}",
            f"- **Phase**: {grow.get('current_phase', 'Unknown')}",
            f"- **Start Date**: {grow.get('start_date', 'Unknown')}",
            f"- **Light**: {grow.get('light_type', 'Unknown')} "
            f"@ {grow.get('light_wattage', '?')}W",
            f"- **Space**: {grow.get('space_width_cm', '?')}cm × "
            f"{grow.get('space_length_cm', '?')}cm × "
            f"{grow.get('space_height_cm', '?')}cm",
        ]

        # Extract optimal ranges from AI plan
        ai_plan = grow.get("ai_plan")
        if ai_plan and isinstance(ai_plan, dict):
            current_phase = grow.get("current_phase", "vegetative")
            phases = ai_plan.get("phases", [])
            for phase_data in phases:
                if phase_data.get("phase") == current_phase:
                    env = phase_data.get("environment", {})
                    nutr = phase_data.get("nutrients", {})
                    parts.append("\n### Optimal Ranges (AI Plan)")
                    parts.append(
                        f"- Temp Day: {env.get('temperature_day_c', '?')}°C | "
                        f"Night: {env.get('temperature_night_c', '?')}°C"
                    )
                    parts.append(
                        f"- Humidity: {env.get('humidity_percent', '?')}%"
                    )
                    parts.append(
                        f"- VPD: {env.get('vpd_min', '?')} - "
                        f"{env.get('vpd_max', '?')} kPa"
                    )
                    parts.append(
                        f"- pH: {nutr.get('ph_min', '?')} - "
                        f"{nutr.get('ph_max', '?')}"
                    )
                    parts.append(
                        f"- EC: {nutr.get('ec_min', '?')} - "
                        f"{nutr.get('ec_max', '?')}"
                    )
                    parts.append(
                        f"- Light Hours: {env.get('light_hours', '?')}h"
                    )
                    break

        # Load recent snapshots (sync, will be called in context)
        try:
            snap_result = (
                self.supabase.table("grow_snapshots")
                .select("*")
                .eq("grow_id", grow_id)
                .order("recorded_at", desc=True)
                .limit(3)
                .execute()
            )

            if snap_result.data:
                parts.append("\n### Recent Sensor Readings")
                for snap in reversed(snap_result.data):
                    ts = snap.get("recorded_at", "?")
                    parts.append(
                        f"- [{ts}] Temp: {snap.get('temperature', '?')}°C | "
                        f"Humidity: {snap.get('humidity', '?')}% | "
                        f"pH: {snap.get('ph', '?')} | "
                        f"EC: {snap.get('ec', '?')} | "
                        f"VPD: {snap.get('vpd', '?')} kPa"
                    )
        except Exception as e:
            logger.warning("Failed to load snapshots: %s", e)

        return "\n".join(parts)

    # ------------------------------------------------------------------
    # Chat History & Summarization
    # ------------------------------------------------------------------

    async def _load_chat_history(self, user_id: str) -> List[Dict[str, str]]:
        """Load last N chat messages for context window."""
        try:
            result = await asyncio.to_thread(
                lambda: self.supabase.table("chat_messages")
                .select("role, content")
                .eq("user_id", user_id)
                .order("created_at", desc=True)
                .limit(MAX_HISTORY_MESSAGES)
                .execute()
            )
            # Reverse so oldest first
            rows = list(reversed(result.data or []))
            return [{"role": r["role"], "content": r["content"]} for r in rows]
        except Exception as e:
            logger.warning("Failed to load chat history: %s", e)
            return []

    async def _load_summaries(self, user_id: str) -> Optional[str]:
        """Load the latest chat summary for context compression."""
        try:
            result = await asyncio.to_thread(
                lambda: self.supabase.table("chat_summaries")
                .select("summary")
                .eq("user_id", user_id)
                .order("created_at", desc=True)
                .limit(1)
                .execute()
            )
            if result.data:
                return result.data[0]["summary"]
            return None
        except Exception as e:
            logger.warning("Failed to load summaries: %s", e)
            return None

    async def _maybe_summarize(self, user_id: str) -> None:
        """If the user has accumulated enough messages, summarize older ones."""
        try:
            count_result = await asyncio.to_thread(
                lambda: self.supabase.table("chat_messages")
                .select("id", count="exact")
                .eq("user_id", user_id)
                .execute()
            )
            total = count_result.count or 0

            if total > 0 and total % SUMMARIZE_EVERY == 0:
                logger.info(
                    "Triggering auto-summarization for user %s (total: %d)",
                    user_id, total,
                )
                await self._summarize_history(user_id)

        except Exception as e:
            logger.warning("Summarization check failed: %s", e)

    async def _summarize_history(self, user_id: str) -> None:
        """Summarize all messages except the last N and store as summary."""
        try:
            # Load all messages
            result = await asyncio.to_thread(
                lambda: self.supabase.table("chat_messages")
                .select("role, content, created_at")
                .eq("user_id", user_id)
                .order("created_at", desc=False)
                .execute()
            )
            all_msgs = result.data or []

            if len(all_msgs) <= MAX_HISTORY_MESSAGES:
                return

            # Messages to summarize (everything except last N)
            to_summarize = all_msgs[:-MAX_HISTORY_MESSAGES]
            convo_text = "\n".join(
                f"{m['role']}: {m['content']}" for m in to_summarize
            )

            # Get existing summary context
            existing_summary = await self._load_summaries(user_id)
            summary_prompt = (
                "Summarize the following conversation between a cannabis grower "
                "and Dr. Aurora (AI cultivation doctor). "
                "Preserve key facts: strain, issues discussed, advice given, "
                "environmental readings mentioned, and any ongoing concerns.\n"
                "Keep the summary concise (under 300 words).\n\n"
            )
            if existing_summary:
                summary_prompt += (
                    f"Previous summary:\n{existing_summary}\n\n"
                    f"New messages to integrate:\n{convo_text}"
                )
            else:
                summary_prompt += f"Conversation:\n{convo_text}"

            messages = [
                {"role": "system", "content": "You are a conversation summarizer. Output only the summary, nothing else."},
                {"role": "user", "content": summary_prompt},
            ]

            summary_text = await asyncio.to_thread(
                self._call_groq_with_retry, messages
            )

            # Save summary
            await asyncio.to_thread(
                lambda: self.supabase.table("chat_summaries")
                .insert({
                    "user_id": user_id,
                    "summary": summary_text,
                    "message_count": len(to_summarize),
                })
                .execute()
            )

            # Delete summarized messages to compress context
            msg_ids = [m.get("id") for m in to_summarize if m.get("id")]
            if msg_ids:
                # We need to reload with IDs
                id_result = await asyncio.to_thread(
                    lambda: self.supabase.table("chat_messages")
                    .select("id")
                    .eq("user_id", user_id)
                    .order("created_at", desc=False)
                    .limit(len(to_summarize))
                    .execute()
                )
                for row in (id_result.data or []):
                    await asyncio.to_thread(
                        lambda rid=row["id"]: self.supabase.table("chat_messages")
                        .delete()
                        .eq("id", rid)
                        .execute()
                    )

            logger.info("Summarized %d messages for user %s", len(to_summarize), user_id)

        except Exception as e:
            logger.error("History summarization failed: %s", e)

    # ------------------------------------------------------------------
    # Token Budget Management
    # ------------------------------------------------------------------

    def _trim_history_to_budget(
        self,
        history: List[Dict[str, str]],
        token_budget: int,
    ) -> List[Dict[str, str]]:
        """Trim history from the oldest messages to fit within token budget."""
        if token_budget <= 0:
            return []

        result: List[Dict[str, str]] = []
        running_total = 0

        # Start from most recent
        for msg in reversed(history):
            msg_tokens = _count_tokens(msg["content"])
            if running_total + msg_tokens > token_budget:
                break
            result.insert(0, msg)
            running_total += msg_tokens

        return result

    # ------------------------------------------------------------------
    # Groq Interaction
    # ------------------------------------------------------------------

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
    )
    def _call_groq_with_retry(self, messages: List[Dict[str, str]]) -> str:
        """
        Synchronous Groq call with tenacity retry.
        Runs inside asyncio.to_thread.
        """
        response = self.groq.chat.completions.create(
            model=MODEL,
            messages=messages,
            temperature=TEMPERATURE,
            max_tokens=MAX_TOKENS,
        )
        return response.choices[0].message.content

    # ------------------------------------------------------------------
    # Database Persistence
    # ------------------------------------------------------------------

    async def _save_message(
        self,
        user_id: str,
        role: str,
        content: str,
        metadata: Optional[dict] = None,
    ) -> str:
        """Save a chat message to the database and return its ID."""
        msg_id = str(uuid4())
        try:
            await asyncio.to_thread(
                lambda: self.supabase.table("chat_messages")
                .insert({
                    "id": msg_id,
                    "user_id": user_id,
                    "role": role,
                    "content": content,
                    "metadata": metadata or {},
                })
                .execute()
            )
            return msg_id
        except Exception as e:
            logger.error("Failed to save message: %s", e)
            return msg_id  # Return ID anyway for response

    # ------------------------------------------------------------------
    # Emergency Notifications
    # ------------------------------------------------------------------

    async def _create_emergency_notification(
        self,
        user_id: str,
        user_message: str,
        response: str,
    ) -> None:
        """Create a push notification record for emergency situations."""
        try:
            # Truncate for notification body
            body = response[:200] + "..." if len(response) > 200 else response

            await asyncio.to_thread(
                lambda: self.supabase.table("notifications")
                .insert({
                    "user_id": user_id,
                    "type": "alert",
                    "title": "🚨 Dr. Aurora — Emergency Alert",
                    "body": body,
                    "data": {
                        "type": "emergency_chat",
                        "user_message": user_message[:500],
                    },
                    "is_read": False,
                })
                .execute()
            )
            logger.info("Emergency notification created for user %s", user_id)

            # Placeholder: In production, trigger actual push notification
            # via Firebase Cloud Messaging here using the user's
            # notification_token from profiles table.

        except Exception as e:
            logger.error("Failed to create emergency notification: %s", e)

    async def stream_message(
        self,
        user_id: str,
        message: str,
        grow_id: Optional[str] = None,
    ) -> AsyncIterator[str]:
        """
        Stream Dr. Aurora's response chunk by chunk.
        """
        if not self.async_groq:
             raise ChatServiceError("AsyncGroq client not initialized")

        try:
            # Detect intent
            intent, is_emergency = self._detect_intent(message)
            
            # Load basic context (Simplified for streaming)
            grow_info = await self._get_grow_info(user_id, grow_id) if grow_id else await self._get_active_grow_info(user_id)
            context = ""
            if grow_info:
                context = self._format_grow_context(grow_info, grow_info["id"])

            system_content = DR_AURORA_SYSTEM_PROMPT
            if context:
                system_content += f"\n\n## Current Context\n{context}"

            messages = [
                {"role": "system", "content": system_content},
                {"role": "user", "content": message},
            ]

            stream = await self.async_groq.chat.completions.create(
                model=MODEL,
                messages=messages,
                temperature=TEMPERATURE,
                max_tokens=MAX_TOKENS,
                stream=True,
            )

            full_response = ""
            async for chunk in stream:
                content = chunk.choices[0].delta.content
                if content:
                    full_response += content
                    yield content

            # After streaming is done, save the messages to DB
            await self._save_message(user_id, "user", message, {"intent": intent})
            await self._save_message(user_id, "assistant", full_response, {"intent": intent})

        except Exception as e:
            logger.error(f"Streaming failed: {e}")
            yield f"Error: {str(e)}"
