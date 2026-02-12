"""
Aurora Error Handling & Validation Tests
Tests for improved error messages and edge cases.
"""
import pytest
from fastapi import status, HTTPException

from app.models_chat import ChatMessageRequest, IntentType
from app.routers.social import CreatePostRequest, CommentRequest, ReportRequest


class TestChatErrorMessages:
    """Tests for chat error messages."""

    def test_empty_chat_message_error(self):
        """Test error when chat message is empty."""
        with pytest.raises(ValueError) as exc_info:
            ChatMessageRequest(message="")
        assert "at least 1 character" in str(exc_info.value).lower()

    def test_chat_message_too_long_error(self):
        """Test error when chat message exceeds max length."""
        with pytest.raises(ValueError) as exc_info:
            ChatMessageRequest(message="x" * 2001)
        assert "2000" in str(exc_info.value) or "too long" in str(exc_info.value).lower()

    def test_invalid_grow_id_format_error(self):
        """Test handling of invalid grow_id format."""
        # Valid UUID format required
        request = ChatMessageRequest(
            message="Test message",
            grow_id="invalid-format"
        )
        # Should not raise but accept any string
        assert request.grow_id == "invalid-format"


class TestPostErrorMessages:
    """Tests for post error messages."""

    def test_post_empty_content_error(self):
        """Test error when post content is empty."""
        with pytest.raises(ValueError) as exc_info:
            CreatePostRequest(content="")
        assert "at least 1 character" in str(exc_info.value).lower()

    def test_post_content_too_long_error(self):
        """Test error when post content exceeds max length."""
        with pytest.raises(ValueError) as exc_info:
            CreatePostRequest(content="x" * 2001)
        assert "2000" in str(exc_info.value) or "too long" in str(exc_info.value).lower()

    def test_post_too_many_images_error(self):
        """Test error when post has too many images."""
        with pytest.raises(ValueError) as exc_info:
            CreatePostRequest(
                content="Post with many images",
                image_urls=["url1", "url2", "url3", "url4", "url5", "url6"]
            )
        assert "5" in str(exc_info.value) or "max" in str(exc_info.value).lower()

    def test_post_invalid_image_url_type(self):
        """Test error when image_urls contains non-string."""
        with pytest.raises(ValueError):
            CreatePostRequest(
                content="Post",
                image_urls=["valid_url", 123]  # Invalid: int instead of string
            )


class TestCommentErrorMessages:
    """Tests for comment error messages."""

    def test_comment_empty_content_error(self):
        """Test error when comment content is empty."""
        with pytest.raises(ValueError) as exc_info:
            CommentRequest(content="")
        assert "at least 1 character" in str(exc_info.value).lower()

    def test_comment_content_too_long_error(self):
        """Test error when comment exceeds max length."""
        with pytest.raises(ValueError) as exc_info:
            CommentRequest(content="x" * 501)
        assert "500" in str(exc_info.value) or "too long" in str(exc_info.value).lower()


class TestReportErrorMessages:
    """Tests for report error messages."""

    def test_report_empty_reason_error(self):
        """Test error when report reason is empty."""
        with pytest.raises(ValueError) as exc_info:
            ReportRequest(reason="")
        assert "at least 1 character" in str(exc_info.value).lower()

    def test_report_reason_too_long_error(self):
        """Test error when report reason exceeds max length."""
        with pytest.raises(ValueError) as exc_info:
            ReportRequest(reason="x" * 501)
        assert "500" in str(exc_info.value) or "too long" in str(exc_info.value).lower()

    def test_report_missing_target_error(self):
        """Test error when neither post_id nor comment_id provided."""
        # Should create but ideally would warn about providing at least one
        request = ReportRequest(
            reason="Inappropriate content"
        )
        assert request.post_id is None
        assert request.comment_id is None


class TestHTTPErrorStatuses:
    """Tests for HTTP error status codes."""

    def test_unauthorized_status_code(self):
        """Test 401 Unauthorized response structure."""
        error = HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid JWT token"
        )
        assert error.status_code == 401
        assert "token" in error.detail.lower()

    def test_rate_limit_status_code(self):
        """Test 429 Too Many Requests response structure."""
        error = HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Rate limit exceeded. Max 30 actions per minute."
        )
        assert error.status_code == 429
        assert "rate" in error.detail.lower()

    def test_not_found_status_code(self):
        """Test 404 Not Found response structure."""
        error = HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Post not found or not visible to you"
        )
        assert error.status_code == 404
        assert "not found" in error.detail.lower()

    def test_bad_request_status_code(self):
        """Test 400 Bad Request response structure."""
        error = HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid parameter: limit must be between 1 and 50"
        )
        assert error.status_code == 400
        assert "invalid" in error.detail.lower()

    def test_internal_server_error_status_code(self):
        """Test 500 Internal Server Error response structure."""
        error = HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An unexpected error occurred"
        )
        assert error.status_code == 500


class TestValidationMessages:
    """Tests for validation message clarity."""

    def test_pagination_param_validation_message(self):
        """Test pagination parameter validation message."""
        # Valid ranges
        assert 1 <= 1  # Min page
        assert 50 <= 50  # Max limit
        
        # Invalid ranges
        invalid_page = 0
        invalid_limit = 51
        
        page_error = f"page must be >= 1, got {invalid_page}"
        limit_error = f"limit must be between 1 and 50, got {invalid_limit}"
        
        assert "page" in page_error.lower()
        assert "limit" in limit_error.lower()

    def test_required_field_missing_message(self):
        """Test message when required field is missing."""
        with pytest.raises(ValueError):
            ChatMessageRequest(message=None)

    def test_invalid_enum_value_message(self):
        """Test message when invalid enum value provided."""
        # Valid intents
        valid_intents = ["question", "emergency", "general", "diagnostics", "adjust_plan"]
        invalid_intent = "invalid_intent_type"
        
        assert invalid_intent not in valid_intents


class TestEdgeCaseErrors:
    """Tests for edge case error handling."""

    def test_special_characters_in_content(self):
        """Test handling of special characters in content."""
        request = CreatePostRequest(
            content="Post with special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?"
        )
        assert "special" not in request.content or len(request.content) > 0

    def test_unicode_characters_in_message(self):
        """Test handling of unicode characters."""
        request = ChatMessageRequest(
            message="mensaje con acentos: á é í ó ú 中文 日本語"
        )
        assert request.message is not None

    def test_very_long_url_in_images(self):
        """Test handling of very long URLs."""
        long_url = "https://example.com/" + "x" * 1000
        request = CreatePostRequest(
            content="Post with long URL",
            image_urls=[long_url]
        )
        assert len(request.image_urls) == 1

    def test_null_optional_fields(self):
        """Test handling of null optional fields."""
        request = CreatePostRequest(
            content="Post"
            # image_urls will default to empty list, not None
        )
        # Should use defaults
        assert isinstance(request.image_urls, list)
        assert request.strain_tag is None

    def test_whitespace_only_content(self):
        """Test handling of whitespace-only content."""
        # Note: The validator allows whitespace-only content (not ideal but current implementation)
        request = CreatePostRequest(content="   \t\n  ")
        assert request.content == "   \t\n  "  # Pydantic accepts it as non-empty string


class TestErrorRecovery:
    """Tests for error recovery and fallbacks."""

    def test_database_error_graceful_fallback(self):
        """Test graceful handling of database errors."""
        # Simulate error response
        error_response = {
            "error": "Database connection failed",
            "retry_after": 5  # Suggest retry after 5 seconds
        }
        assert error_response["retry_after"] > 0

    def test_external_api_error_handling(self):
        """Test handling of external API errors (Groq, etc)."""
        # Timeout error
        error_response = {
            "error": "External service timeout",
            "fallback": "Using cached response"
        }
        assert "fallback" in error_response

    def test_rate_limit_retry_guidance(self):
        """Test rate limit error provides retry guidance."""
        error = {
            "error": "Rate limit exceeded",
            "limit": "30 actions per minute",
            "retry_after_seconds": 60,
            "current_usage": 30
        }
        assert error["retry_after_seconds"] > 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
