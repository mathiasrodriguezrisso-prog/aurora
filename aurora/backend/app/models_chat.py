"""
Aurora Backend - Chat Models (Dr. Aurora)
Pydantic schemas for chat requests, responses, and intent detection.
"""
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime
from enum import Enum


class IntentType(str, Enum):
    """Detected intent from user message."""
    QUESTION = "question"
    EMERGENCY = "emergency"
    GENERAL = "general"
    ADJUST_PLAN = "adjust_plan"
    DIAGNOSTICS = "diagnostics"


class ChatRole(str, Enum):
    """Chat message role."""
    USER = "user"
    ASSISTANT = "assistant"
    SYSTEM = "system"


# ============================================
# Request Models
# ============================================

class ChatMessageRequest(BaseModel):
    """Request model for sending a chat message."""
    message: str = Field(
        ...,
        min_length=1,
        max_length=2000,
        description="User message to Dr. Aurora",
    )
    grow_id: Optional[str] = Field(
        default=None,
        description="Optional grow ID for context-specific chat",
    )
    image_url: Optional[str] = Field(
        default=None,
        description="Optional image URL for photo-based diagnosis",
    )


# ============================================
# Response Models
# ============================================

class ChatMessageMetadata(BaseModel):
    """Metadata attached to a chat response."""
    intent: IntentType = Field(
        default=IntentType.GENERAL,
        description="Detected intent of the user message",
    )
    is_emergency: bool = Field(
        default=False,
        description="Whether this was flagged as an emergency",
    )
    tokens_used: int = Field(
        default=0,
        description="Total tokens consumed in this exchange",
    )
    context_sources: List[str] = Field(
        default_factory=list,
        description="Sources used for context (grow data, snapshots, etc.)",
    )


class ChatMessageResponse(BaseModel):
    """Response model for a chat message."""
    id: str = Field(..., description="Message UUID")
    role: ChatRole = Field(..., description="Message role")
    content: str = Field(..., description="Message content")
    metadata: ChatMessageMetadata = Field(
        default_factory=ChatMessageMetadata,
        description="Response metadata",
    )
    created_at: str = Field(..., description="ISO timestamp")


class ChatHistoryMessage(BaseModel):
    """A single message in chat history."""
    id: str = Field(..., description="Message UUID")
    role: ChatRole = Field(..., description="Message role")
    content: str = Field(..., description="Message content")
    metadata: Optional[dict] = Field(default=None, description="Message metadata")
    created_at: str = Field(..., description="ISO timestamp")


class ChatHistoryResponse(BaseModel):
    """Response model for chat history."""
    success: bool = Field(default=True)
    messages: List[ChatHistoryMessage] = Field(
        default_factory=list,
        description="List of chat messages",
    )
    has_more: bool = Field(
        default=False,
        description="Whether there are more messages to load",
    )
    total_count: int = Field(
        default=0,
        description="Total number of messages for this user",
    )
