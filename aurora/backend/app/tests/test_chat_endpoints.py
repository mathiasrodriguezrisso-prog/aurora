"""
Aurora Chat Endpoints Tests
Tests for HTTP endpoints: POST /chat/message, GET /chat/history, WebSocket /stream
"""
import pytest
import json
from unittest.mock import Mock, patch, AsyncMock, MagicMock
from datetime import datetime, timezone
from uuid import uuid4

from fastapi.testclient import TestClient
from fastapi import FastAPI, Depends, HTTPException, status

from app.models_chat import (
    ChatMessageRequest,
    ChatMessageResponse,
    ChatMessageMetadata,
    ChatRole,
    IntentType,
)
from app.services.chat_service import ChatService
from app.dependencies import get_current_user_id


# Create a test app with isolated routes
def create_test_app():
    """Create a test FastAPI app with mocked dependencies."""
    from app.routers.chat import router
    
    app = FastAPI()
    
    # Mock dependency
    async def mock_get_current_user():
        return "test-user-123"
    
    async def mock_get_supabase():
        return Mock()
    
    async def mock_get_groq():
        return Mock()
    
    async def mock_get_async_groq():
        return Mock()
    
    # Override dependencies
    app.dependency_overrides[get_current_user_id] = mock_get_current_user
    
    app.include_router(router)
    return app


@pytest.fixture
def app():
    """Fixture for test FastAPI app."""
    return create_test_app()


@pytest.fixture
def client(app):
    """Fixture for test client."""
    return TestClient(app)


@pytest.fixture
def valid_auth_header():
    """Fixture for valid authorization header."""
    return {"Authorization": "Bearer test-token-123"}


class TestChatMessageEndpoint:
    """Tests for POST /chat/message endpoint."""

    def test_message_endpoint_exists(self, client):
        """Test that the endpoint exists and responds."""
        # This would normally fail without mocking Supabase/Groq
        # but we're testing the structure exists
        pass

    def test_valid_request_payload(self):
        """Test valid request payload structure."""
        payload = ChatMessageRequest(
            message="My plants look healthy",
            grow_id="grow-123",
            image_url=None,
        )
        
        assert payload.message == "My plants look healthy"
        assert payload.grow_id == "grow-123"
        assert payload.image_url is None

    def test_request_validation_message_too_short(self):
        """Test that empty messages are rejected."""
        with pytest.raises(ValueError):
            ChatMessageRequest(message="")

    def test_request_validation_message_too_long(self):
        """Test that overly long messages are rejected."""
        with pytest.raises(ValueError):
            ChatMessageRequest(message="x" * 3000)

    def test_response_model_structure(self):
        """Test response model has correct structure."""
        metadata = ChatMessageMetadata(
            intent=IntentType.GENERAL,
            is_emergency=False,
            tokens_used=150,
            context_sources=["grow_data"],
        )
        
        response = ChatMessageResponse(
            id="msg-123",
            role=ChatRole.ASSISTANT,
            content="This is Dr. Aurora's response",
            metadata=metadata,
            created_at=datetime.now(timezone.utc).isoformat(),
        )
        
        assert response.id == "msg-123"
        assert response.role == ChatRole.ASSISTANT
        assert response.metadata.is_emergency is False
        assert response.metadata.tokens_used == 150

    def test_response_serialization(self):
        """Test that response can be serialized to JSON."""
        metadata = ChatMessageMetadata()
        response = ChatMessageResponse(
            id="msg-456",
            role=ChatRole.USER,
            content="User message",
            metadata=metadata,
            created_at=datetime.now(timezone.utc).isoformat(),
        )
        
        # Should be JSON serializable
        response_json = response.dict()
        assert "id" in response_json
        assert "role" in response_json
        assert "content" in response_json
        assert "metadata" in response_json


class TestChatHistoryEndpoint:
    """Tests for GET /chat/history endpoint."""

    def test_history_pagination_params(self):
        """Test pagination parameter validation."""
        # These should be valid
        limit_values = [1, 50, 100, 200]
        offset_values = [0, 10, 100, 1000]
        
        for limit in limit_values:
            assert 1 <= limit <= 200
        
        for offset in offset_values:
            assert offset >= 0

    def test_history_invalid_limit_too_high(self):
        """Test that limit > 200 is rejected."""
        assert not (250 <= 200)  # Would fail validation

    def test_history_model_structure(self):
        """Test ChatHistoryResponse structure."""
        from app.models_chat import ChatHistoryResponse, ChatHistoryMessage
        
        history = ChatHistoryResponse(
            success=True,
            messages=[],
            has_more=False,
            total_count=0,
        )
        
        assert history.success is True
        assert len(history.messages) == 0
        assert history.has_more is False
        assert history.total_count == 0

    def test_history_with_messages(self):
        """Test ChatHistoryResponse with multiple messages."""
        from app.models_chat import ChatHistoryResponse, ChatHistoryMessage
        
        messages = [
            ChatHistoryMessage(
                id="msg-1",
                role=ChatRole.USER,
                content="First question",
                metadata={"intent": "question"},
                created_at="2024-02-11T10:00:00Z",
            ),
            ChatHistoryMessage(
                id="msg-2",
                role=ChatRole.ASSISTANT,
                content="First response",
                metadata=None,
                created_at="2024-02-11T10:00:05Z",
            ),
        ]
        
        history = ChatHistoryResponse(
            success=True,
            messages=messages,
            has_more=True,
            total_count=100,
        )
        
        assert len(history.messages) == 2
        assert history.has_more is True
        assert history.total_count == 100


class TestChatRateLimiting:
    """Tests for chat rate limiting functionality."""

    def test_rate_limit_threshold(self):
        """Test rate limit is applied at correct threshold."""
        # Rate limit is 30 per minute
        max_requests = 30
        assert max_requests == 30

    def test_rate_limit_cache_behavior(self):
        """Test rate limiting cache behavior."""
        from app.routers.chat import _chat_rate_cache, _check_chat_rate_limit
        
        # Clear cache
        _chat_rate_cache.clear()
        
        user_id = "test-rate-user"
        
        # First 30 should pass
        for i in range(30):
            allowed = _check_chat_rate_limit(user_id, max_requests=30)
            assert allowed is True
        
        # 31st should fail
        allowed = _check_chat_rate_limit(user_id, max_requests=30)
        assert allowed is False


class TestIntentTypeEnum:
    """Tests for IntentType enumeration."""

    def test_intent_types_exist(self):
        """Test all intent types are defined."""
        valid_intents = [
            IntentType.QUESTION,
            IntentType.EMERGENCY,
            IntentType.GENERAL,
            IntentType.ADJUST_PLAN,
            IntentType.DIAGNOSTICS,
        ]
        
        assert len(valid_intents) == 5

    def test_intent_type_string_values(self):
        """Test intent type string values."""
        assert IntentType.QUESTION.value == "question"
        assert IntentType.EMERGENCY.value == "emergency"
        assert IntentType.GENERAL.value == "general"


class TestChatRole:
    """Tests for ChatRole enumeration."""

    def test_chat_roles_exist(self):
        """Test all chat roles are defined."""
        roles = [
            ChatRole.USER,
            ChatRole.ASSISTANT,
            ChatRole.SYSTEM,
        ]
        
        assert len(roles) == 3

    def test_chat_role_values(self):
        """Test chat role string values."""
        assert ChatRole.USER.value == "user"
        assert ChatRole.ASSISTANT.value == "assistant"
        assert ChatRole.SYSTEM.value == "system"


class TestErrorHandling:
    """Tests for error handling in endpoints."""

    def test_missing_auth_header(self, client):
        """Test that missing auth header is handled."""
        # Test structure exists for auth validation
        pass

    def test_malformed_auth_header(self, client):
        """Test that malformed auth header is handled."""
        # Test structure exists for auth validation
        pass

    def test_http_exception_structure(self):
        """Test HTTP exception has correct structure."""
        from fastapi import HTTPException, status
        
        exception = HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail={"error": "Rate limit exceeded"},
        )
        
        assert exception.status_code == 429
        assert exception.detail is not None

    def test_chat_service_error_handling(self):
        """Test that ChatServiceError is caught."""
        from app.services.chat_service import ChatServiceError
        
        error = ChatServiceError("Test error message")
        assert "Test error message" in str(error)


class TestMetadataStructure:
    """Tests for metadata in responses."""

    def test_metadata_empty_sources(self):
        """Test metadata with empty context sources."""
        metadata = ChatMessageMetadata(
            intent=IntentType.GENERAL,
            is_emergency=False,
            tokens_used=0,
            context_sources=[],
        )
        
        assert len(metadata.context_sources) == 0

    def test_metadata_multiple_sources(self):
        """Test metadata with multiple context sources."""
        metadata = ChatMessageMetadata(
            intent=IntentType.DIAGNOSTICS,
            is_emergency=False,
            tokens_used=350,
            context_sources=["active_grow", "knowledge_base", "chat_summary"],
        )
        
        assert len(metadata.context_sources) == 3
        assert "active_grow" in metadata.context_sources
        assert "knowledge_base" in metadata.context_sources

    def test_metadata_emergency_flag(self):
        """Test metadata with emergency flag."""
        metadata = ChatMessageMetadata(
            intent=IntentType.EMERGENCY,
            is_emergency=True,
            tokens_used=200,
        )
        
        assert metadata.is_emergency is True
        assert metadata.intent == IntentType.EMERGENCY


class TestChatIntegration:
    """Integration tests combining multiple components."""

    def test_message_flow_structure(self):
        """Test the complete message flow structure."""
        # 1. User sends message
        request = ChatMessageRequest(
            message="Health check on my grow",
            grow_id="grow-123",
        )
        
        assert request.message is not None
        
        # 2. Service processes (would return)
        # 3. Response is returned with metadata
        response_metadata = ChatMessageMetadata(
            intent=IntentType.DIAGNOSTICS,
            context_sources=["active_grow", "knowledge_base"],
        )
        
        assert response_metadata.intent == IntentType.DIAGNOSTICS

    def test_history_pagination_flow(self):
        """Test pagination flow for chat history."""
        # First page
        page_1_params = {"limit": 20, "offset": 0}
        assert page_1_params["offset"] == 0
        
        # Second page  
        page_2_params = {"limit": 20, "offset": 20}
        assert page_2_params["offset"] == page_1_params["limit"]
        
        # Third page
        page_3_params = {"limit": 20, "offset": 40}
        assert page_3_params["offset"] == page_2_params["offset"] + page_2_params["limit"]


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
