"""
Simple Groq client manager to centralize API key usage and optional rotation.
"""
import os
import logging
from groq import Groq, AsyncGroq
from app.config import settings

logger = logging.getLogger(__name__)


def get_groq_client():
    api_key = os.getenv("GROQ_API_KEY") or settings.groq_api_key
    if not api_key:
        logger.warning("GROQ_API_KEY not set; Groq calls will fail")
    return Groq(api_key=api_key)


def get_async_groq_client():
    api_key = os.getenv("GROQ_API_KEY") or settings.groq_api_key
    if not api_key:
        logger.warning("GROQ_API_KEY not set; AsyncGroq calls will fail")
    return AsyncGroq(api_key=api_key)


def call_groq_json(client: Groq, messages: list, model: str = "llama-3.1-8b-instant", temperature: float = 0.3, max_tokens: int = 2000) -> dict:
    """Call Groq chat completions enforcing JSON response format and return parsed JSON.

    Raises an exception if parsing fails.
    """
    response = client.chat.completions.create(
        model=model,
        messages=messages,
        temperature=temperature,
        max_tokens=max_tokens,
        response_format={"type": "json_object"},
    )
    content = response.choices[0].message.content
    try:
        import json

        return json.loads(content)
    except Exception as e:
        logger.error("Failed to parse Groq JSON response: %s", e)
        raise


async def async_call_groq_json(client: AsyncGroq, messages: list, model: str = "llama-3.1-8b-instant", temperature: float = 0.3, max_tokens: int = 2000) -> dict:
    """Async version of call_groq_json."""
    response = await client.chat.completions.create(
        model=model,
        messages=messages,
        temperature=temperature,
        max_tokens=max_tokens,
        response_format={"type": "json_object"},
    )
    content = response.choices[0].message.content
    import json

    return json.loads(content)
