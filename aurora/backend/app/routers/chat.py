"""
Aurora Chat Router — Dr. Aurora Endpoints
"""
import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status, Query, WebSocket, WebSocketDisconnect
from supabase import Client
from groq import Groq
from cachetools import TTLCache

from app.dependencies import get_supabase, get_groq, get_async_groq, get_current_user_id
from app.models_chat import (
    ChatMessageRequest,
    ChatMessageResponse,
    ChatMessageMetadata,
    ChatHistoryResponse,
    ChatHistoryMessage,
    ChatRole,
)
from app.services.chat_service import ChatService, ChatServiceError

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/chat", tags=["Chat"])

# Rate limiting: 30 messages per minute per user
_chat_rate_cache: TTLCache = TTLCache(maxsize=2000, ttl=60)


def _check_chat_rate_limit(user_id: str, max_requests: int = 30) -> bool:
    """Return True if the user is within rate limits."""
    current = _chat_rate_cache.get(user_id, 0)
    if current >= max_requests:
        return False
    _chat_rate_cache[user_id] = current + 1
    return True


# ------------------------------------------------------------------
# POST /message
# ------------------------------------------------------------------

@router.post(
    "/message",
    response_model=ChatMessageResponse,
    status_code=status.HTTP_200_OK,
)
async def send_chat_message(
    request: ChatMessageRequest,
    supabase: Client = Depends(get_supabase),
    groq: Groq = Depends(get_groq),
    user_id: str = Depends(get_current_user_id),
):
    """
    Send a message to Dr. Aurora and get a contextual response.
    """
    if not _check_chat_rate_limit(user_id):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={
                "error": "Rate limit exceeded",
                "detail": "Max 30 messages per minute",
                "retry_after_seconds": 60,
                "code": "RATE_001"
            },
        )

    try:
        chat_service = ChatService(groq, supabase)
        response = await chat_service.process_message(
            user_id=user_id,
            message=request.message,
            grow_id=request.grow_id,
        )

        return ChatMessageResponse(
            id=response["id"],
            role=ChatRole(response["role"]),
            content=response["content"],
            metadata=ChatMessageMetadata(**response["metadata"]),
            created_at=response["created_at"],
        )

    except ChatServiceError as e:
        logger.error("Chat logic error: %s", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": "Chat service error",
                "detail": str(e),
                "code": "CHAT_SERVICE_ERROR",
            },
        )
    except Exception as e:
        logger.error("Unexpected chat error: %s", e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": "An unexpected error occurred",
                "detail": "Please try again later. If this persists, contact support.",
                "code": "INTERNAL_ERROR",
            },
        )


# ------------------------------------------------------------------
# GET /history
# ------------------------------------------------------------------

@router.get(
    "/history",
    response_model=ChatHistoryResponse,
)
async def get_chat_history(
    limit: int = Query(default=50, ge=1, le=200, description="Max messages"),
    offset: int = Query(default=0, ge=0, description="Offset for pagination"),
    supabase: Client = Depends(get_supabase),
    groq: Groq = Depends(get_groq),
    user_id: str = Depends(get_current_user_id),
):
    """Retrieve paginated chat history for the authenticated user."""
    try:
        chat_service = ChatService(groq, supabase)

        result = await chat_service.get_history(
            user_id=user_id,
            limit=limit,
            offset=offset,
        )

        messages = [
            ChatHistoryMessage(
                id=m["id"],
                role=ChatRole(m["role"]),
                content=m["content"],
                metadata=m.get("metadata"),
                created_at=m["created_at"],
            )
            for m in result.get("messages", [])
        ]

        return ChatHistoryResponse(
            success=True,
            messages=messages,
            has_more=result.get("has_more", False),
            total_count=result.get("total_count", 0),
        )

    except ChatServiceError as e:
        logger.error("History error: %s", e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": "Failed to load chat history",
                "detail": str(e),
                "code": "HISTORY_ERROR"
            },
        )
    except Exception as e:
        logger.error("Unexpected history error: %s", e, exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail={
                "error": "Failed to load chat history",
                "detail": "Please try again later.",
                "code": "INTERNAL_ERROR"
            },
        )


# ------------------------------------------------------------------
# WebSocket /stream
# ------------------------------------------------------------------

@router.websocket("/stream")
async def chat_stream_endpoint(
    websocket: WebSocket,
    user_id: str = Query(...),
    grow_id: Optional[str] = Query(None),
    supabase: Client = Depends(get_supabase),
    groq = Depends(get_groq),
    async_groq = Depends(get_async_groq),
):
    """
    WebSocket endpoint for streaming Dr. Aurora's response.
    """
    await websocket.accept()

    # Rate limit check for streaming
    if not _check_chat_rate_limit(user_id):
        await websocket.send_json({"error": "Rate limit exceeded"})
        await websocket.close()
        return

    try:
        chat_service = ChatService(groq, supabase, async_groq=async_groq)

        # Listen for a single message to start streaming
        data = await websocket.receive_json()
        message_text = data.get("message")

        if not message_text:
            await websocket.send_json({"error": "No message provided"})
            await websocket.close()
            return

        # Stream the response
        async for chunk in chat_service.stream_message(
            user_id=user_id,
            message=message_text,
            grow_id=grow_id,
        ):
            await websocket.send_json({"chunk": chunk})

        await websocket.send_json({"done": True})

    except WebSocketDisconnect:
        logger.info(f"Chat stream disconnected for user {user_id}")
    except Exception as e:
        logger.error(f"Chat stream error: {e}")
        try:
            await websocket.send_json({"error": str(e)})
        except:
            pass
    finally:
        try:
            await websocket.close()
        except:
            pass
