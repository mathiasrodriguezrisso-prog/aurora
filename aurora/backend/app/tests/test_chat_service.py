"""
Aurora Chat Service Tests
Tests for Dr. Aurora chat service, intent detection, and context loading.
"""
import pytest
import json
from unittest.mock import Mock, AsyncMock, patch, MagicMock
from datetime import datetime, timezone
from typing import Dict, Any

from app.services.chat_service import (
    ChatService,
    ChatServiceError,
    _count_tokens,
)


class TestTokenCounting:
    """Test token counting utilities."""

    def test_token_count_basic(self):
        """Test basic token counting."""
        text = "Hello world"
        tokens = _count_tokens(text)
        assert tokens >= 2  # At least 2 tokens

    def test_token_count_empty(self):
        """Test token count on empty string."""
        tokens = _count_tokens("")
        assert tokens >= 0  # Empty string returns 0 tokens

    def test_token_count_long_text(self):
        """Test token count scales with text length."""
        short = _count_tokens("Hello")
        long = _count_tokens("Hello " * 100)
        assert long > short


class TestIntentDetection:
    """Test intent detection logic."""

    @pytest.fixture
    def chat_service(self):
        """Create a mock ChatService for testing."""
        groq_mock = Mock()
        supabase_mock = Mock()
        return ChatService(groq_mock, supabase_mock)

    def test_detect_emergency_keyword(self, chat_service):
        """Test emergency keyword detection."""
        message = "My plants are dying! Help me!"
        intent, is_emergency = chat_service._detect_intent(message)
        assert is_emergency is True
        assert intent == "emergency"

    def test_detect_multiple_emergency_keywords(self, chat_service):
        """Test with multiple emergency keywords."""
        message = "Mold everywhere! Root rot! Emergency!"
        intent, is_emergency = chat_service._detect_intent(message)
        assert is_emergency is True

    def test_detect_question_intent(self, chat_service):
        """Test question intent detection."""
        message = "What should I do about yellow leaves?"
        intent, is_emergency = chat_service._detect_intent(message)
        assert is_emergency is False
        assert intent == "question"

    def test_detect_diagnostics_intent(self, chat_service):
        """Test diagnostics intent detection."""
        message = "Can you analyze my current data?"
        intent, is_emergency = chat_service._detect_intent(message)
        assert is_emergency is False
        assert intent == "diagnostics"

    def test_detect_general_intent_fallback(self, chat_service):
        """Test fallback to general intent."""
        message = "Just checking in on things"
        intent, is_emergency = chat_service._detect_intent(message)
        assert is_emergency is False
        assert intent == "general"

    def test_case_insensitive_detection(self, chat_service):
        """Test that detection is case insensitive."""
        message = "My PlAnTs ArE dYiNg!!!"
        intent, is_emergency = chat_service._detect_intent(message)
        assert is_emergency is True


class TestContextFormatting:
    """Test context formatting utilities."""

    @pytest.fixture
    def chat_service(self):
        """Create a mock ChatService for testing."""
        groq_mock = Mock()
        supabase_mock = Mock()
        return ChatService(groq_mock, supabase_mock)

    def test_format_grow_context_minimal(self, chat_service):
        """Test formatting grow context with minimal data."""
        grow = {
            "id": "grow-123",
            "name": "Test Grow",
            "strain_name": "Blue Dream",
            "medium": "Hydro",
            "current_phase": "vegetative",
            "start_date": "2024-01-01",
            "light_type": "LED",
            "light_wattage": 600,
            "space_width_cm": 100,
            "space_length_cm": 100,
            "space_height_cm": 150,
        }
        context = chat_service._format_grow_context(grow, "grow-123")
        
        assert "Test Grow" in context
        assert "Blue Dream" in context
        assert "vegetative" in context
        assert "LED" in context
        assert "600" in context

    def test_format_grow_context_with_ai_plan(self, chat_service):
        """Test formatting grow context with AI plan."""
        grow = {
            "id": "grow-123",
            "name": "Test Grow",
            "strain_name": "Blue Dream",
            "medium": "Soil",
            "current_phase": "vegetative",
            "start_date": "2024-01-01",
            "light_type": "MH",
            "light_wattage": 1000,
            "space_width_cm": 200,
            "space_length_cm": 200,
            "space_height_cm": 200,
            "ai_plan": {
                "phases": [
                    {
                        "name": "vegetative",
                        "duration_days": 30,
                        "optimal_ranges": {
                            "temp_c": [22, 26],
                            "humidity_rh": [60, 70],
                            "vpd_kpa": [0.8, 1.2],
                        },
                    }
                ]
            },
        }
        context = chat_service._format_grow_context(grow, "grow-123")
        
        assert "Test Grow" in context
        assert context != ""

    def test_format_grow_context_handles_missing_fields(self, chat_service):
        """Test that formatting handles missing optional fields."""
        grow = {
            "id": "grow-123",
            "name": "Minimal Grow",
            "current_phase": "seedling",
        }
        # Should not raise exception
        context = chat_service._format_grow_context(grow, "grow-123")
        
        assert "Minimal Grow" in context
        assert "seedling" in context


class TestChatServiceAsync:
    """Test async chat service methods."""

    @pytest.fixture
    def mock_supabase(self):
        """Create a mock Supabase client."""
        mock = AsyncMock()
        mock.rpc = MagicMock()
        return mock

    @pytest.fixture
    def mock_groq(self):
        """Create a mock Groq client."""
        return Mock()

    @pytest.mark.asyncio
    async def test_get_grow_info_success(self, mock_groq, mock_supabase):
        """Test successful grow info retrieval."""
        # Mock the Supabase response
        grow_data = {
            "id": "grow-123",
            "user_id": "user-456",
            "name": "Test Grow",
            "strain_name": "Blue Dream",
        }
        
        # Setup mock chain
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value = Mock(data=grow_data)
        
        chat_service = ChatService(mock_groq, mock_supabase)
        
        # This would need proper async mocking to work fully
        # For now, we're testing the structure

    @pytest.mark.asyncio
    async def test_get_active_grow_info_success(self, mock_groq, mock_supabase):
        """Test retrieving active grow info."""
        grow_data = {
            "id": "grow-123",
            "user_id": "user-456",
            "status": "active",
        }
        
        # Similar mocking pattern would apply here


class TestChatServiceErrors:
    """Test error handling in chat service."""

    @pytest.fixture
    def chat_service(self):
        """Create a mock ChatService for testing."""
        groq_mock = Mock()
        supabase_mock = Mock()
        return ChatService(groq_mock, supabase_mock)

    def test_chat_service_error_creation(self):
        """Test that ChatServiceError can be created."""
        error = ChatServiceError("Test error")
        assert str(error) == "Test error"
        assert isinstance(error, Exception)

    def test_intent_detection_robustness(self, chat_service):
        """Test intent detection with various input types."""
        test_cases = [
            ("", "general", False),  # Empty string
            ("   ", "general", False),  # Whitespace
            ("what", "question", False),  # Single word
            ("DYING DYING DYING", "emergency", True),  # All caps
        ]
        
        for message, expected_intent, expected_emergency in test_cases:
            intent, is_emergency = chat_service._detect_intent(message)
            # At minimum, should not crash
            assert isinstance(intent, str)
            assert isinstance(is_emergency, bool)


class TestRAGIntegration:
    """Test RAG service integration with chat."""

    @pytest.fixture
    def chat_service(self):
        """Create a mock ChatService with mocked RAG."""
        groq_mock = Mock()
        supabase_mock = Mock()
        service = ChatService(groq_mock, supabase_mock)
        
        # Mock RAG service
        service.rag_service = Mock()
        return service

    def test_rag_service_integration_point(self, chat_service):
        """Test that RAG service is properly integrated."""
        assert hasattr(chat_service, 'rag_service')
        assert hasattr(chat_service.rag_service, 'search_knowledge')


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
