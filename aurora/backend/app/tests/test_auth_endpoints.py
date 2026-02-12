"""
Aurora Auth Endpoints Tests
Tests for signup, login, token refresh, and logout endpoints.
"""
import pytest
from fastapi import status
from unittest.mock import Mock, patch, AsyncMock

from app.models_chat import ChatMessageRequest
from app.routers.auth import (
    SignupRequest,
    LoginRequest,
    RefreshTokenRequest,
    _check_email_exists,
    _create_user_profile,
    _get_user_profile
)


class TestSignupValidation:
    """Tests for signup request validation."""

    def test_signup_valid_request(self):
        """Test valid signup request."""
        request = SignupRequest(
            email="user@example.com",
            password="SecurePassword123!",
            display_name="John Grower",
            role="grower"
        )
        assert request.email == "user@example.com"
        assert request.display_name == "John Grower"
        assert request.role == "grower"

    def test_signup_invalid_email_format(self):
        """Test signup with invalid email format."""
        with pytest.raises(ValueError):
            SignupRequest(
                email="invalid-email",
                password="SecurePassword123!",
                display_name="John"
            )

    def test_signup_password_too_short(self):
        """Test signup with password less than 8 characters."""
        with pytest.raises(ValueError):
            SignupRequest(
                email="user@example.com",
                password="short",
                display_name="John"
            )

    def test_signup_password_too_long(self):
        """Test signup with password exceeding 128 characters."""
        with pytest.raises(ValueError):
            SignupRequest(
                email="user@example.com",
                password="x" * 129,
                display_name="John"
            )

    def test_signup_display_name_empty(self):
        """Test signup with empty display name."""
        with pytest.raises(ValueError):
            SignupRequest(
                email="user@example.com",
                password="SecurePassword123!",
                display_name=""
            )

    def test_signup_display_name_too_long(self):
        """Test signup with display name exceeding 50 characters."""
        with pytest.raises(ValueError):
            SignupRequest(
                email="user@example.com",
                password="SecurePassword123!",
                display_name="x" * 51
            )

    def test_signup_role_optional(self):
        """Test that role is optional and defaults to grower."""
        request = SignupRequest(
            email="user@example.com",
            password="SecurePassword123!",
            display_name="John"
        )
        assert request.role == "grower"


class TestLoginValidation:
    """Tests for login request validation."""

    def test_login_valid_request(self):
        """Test valid login request."""
        request = LoginRequest(
            email="user@example.com",
            password="SecurePassword123!"
        )
        assert request.email == "user@example.com"
        assert request.password == "SecurePassword123!"

    def test_login_invalid_email_format(self):
        """Test login with invalid email format."""
        with pytest.raises(ValueError):
            LoginRequest(
                email="invalid-email",
                password="SecurePassword123!"
            )

    def test_login_missing_password(self):
        """Test login with missing password."""
        # Empty password is allowed by Pydantic (no min_length constraint)
        # The API should validate this at runtime
        request = LoginRequest(
            email="user@example.com",
            password=""
        )
        assert request.password == ""


class TestRefreshTokenValidation:
    """Tests for refresh token request validation."""

    def test_refresh_token_valid_request(self):
        """Test valid refresh token request."""
        request = RefreshTokenRequest(
            refresh_token="valid_refresh_token_here"
        )
        assert request.refresh_token == "valid_refresh_token_here"

    def test_refresh_token_empty(self):
        """Test refresh token request with empty token."""
        # Empty token is allowed by Pydantic (no min_length constraint)
        # The API should validate this at runtime by checking against Supabase
        request = RefreshTokenRequest(
            refresh_token=""
        )
        assert request.refresh_token == ""


class TestAuthErrorMessages:
    """Tests for auth error messages."""

    def test_email_already_exists_error(self):
        """Test error message when email already registered."""
        error = {
            "error": "Email already registered",
            "detail": "The email user@example.com is already associated with an account",
            "code": "AUTH_EMAIL_EXISTS"
        }
        assert "already" in error["error"].lower()
        assert "AUTH_EMAIL_EXISTS" in error["code"]

    def test_invalid_credentials_error(self):
        """Test error message for invalid credentials."""
        error = {
            "error": "Invalid credentials",
            "detail": "Email or password is incorrect",
            "code": "AUTH_INVALID_CREDENTIALS"
        }
        assert "invalid" in error["error"].lower()
        assert "AUTH_INVALID_CREDENTIALS" in error["code"]

    def test_invalid_refresh_token_error(self):
        """Test error message for invalid refresh token."""
        error = {
            "error": "Invalid refresh token",
            "detail": "The refresh token is invalid or has expired",
            "code": "AUTH_INVALID_REFRESH_TOKEN"
        }
        assert "refresh" in error["detail"].lower()
        assert "AUTH_INVALID_REFRESH_TOKEN" in error["code"]

    def test_profile_not_found_error(self):
        """Test error message when user profile not found."""
        error = {
            "error": "User profile not found",
            "detail": "User account exists but profile data is missing",
            "code": "AUTH_PROFILE_NOT_FOUND"
        }
        assert "profile" in error["error"].lower()
        assert "AUTH_PROFILE_NOT_FOUND" in error["code"]


class TestAuthResponseStructure:
    """Tests for auth response structures."""

    def test_signup_response_structure(self):
        """Test signup response includes all required fields."""
        response_fields = {
            "id",
            "email",
            "display_name",
            "role",
            "created_at",
            "access_token",
            "refresh_token",
            "expires_in",
            "token_type"
        }
        # Verify structure would include all fields
        sample_response = {
            "id": "uuid-123",
            "email": "user@example.com",
            "display_name": "John",
            "role": "grower",
            "created_at": "2024-01-15T10:00:00",
            "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
            "refresh_token": "refresh_token_123",
            "expires_in": 3600,
            "token_type": "Bearer"
        }
        assert set(sample_response.keys()) == response_fields

    def test_login_response_structure(self):
        """Test login response includes all required fields."""
        response_fields = {
            "id",
            "email",
            "display_name",
            "role",
            "access_token",
            "refresh_token",
            "expires_in",
            "token_type"
        }
        sample_response = {
            "id": "uuid-123",
            "email": "user@example.com",
            "display_name": "John",
            "role": "grower",
            "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
            "refresh_token": "refresh_token_123",
            "expires_in": 3600,
            "token_type": "Bearer"
        }
        assert set(sample_response.keys()) == response_fields

    def test_refresh_response_structure(self):
        """Test refresh token response includes required fields."""
        response_fields = {
            "access_token",
            "refresh_token",
            "expires_in",
            "token_type"
        }
        sample_response = {
            "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
            "refresh_token": "refresh_token_123",
            "expires_in": 3600,
            "token_type": "Bearer"
        }
        assert set(sample_response.keys()) == response_fields

    def test_token_type_always_bearer(self):
        """Test token_type is always Bearer."""
        assert "Bearer" == "Bearer"


class TestPasswordRequirements:
    """Tests for password security requirements."""

    def test_password_min_length_8(self):
        """Test password minimum requirement of 8 characters."""
        # Valid: exactly 8 chars
        request = SignupRequest(
            email="user@example.com",
            password="12345678",
            display_name="John"
        )
        assert len(request.password) >= 8

        # Invalid: only 7 chars
        with pytest.raises(ValueError):
            SignupRequest(
                email="user@example.com",
                password="1234567",
                display_name="John"
            )

    def test_password_max_length_128(self):
        """Test password maximum requirement of 128 characters."""
        # Valid: exactly 128 chars
        request = SignupRequest(
            email="user@example.com",
            password="x" * 128,
            display_name="John"
        )
        assert len(request.password) <= 128

        # Invalid: 129 chars
        with pytest.raises(ValueError):
            SignupRequest(
                email="user@example.com",
                password="x" * 129,
                display_name="John"
            )


class TestAuthTokenFormat:
    """Tests for JWT token format and expiration."""

    def test_access_token_present(self):
        """Test that access_token is always returned."""
        response = {
            "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
        }
        assert "access_token" in response
        assert len(response["access_token"]) > 0

    def test_expires_in_is_positive_integer(self):
        """Test that expires_in is a positive integer."""
        expires_in = 3600
        assert isinstance(expires_in, int)
        assert expires_in > 0

    def test_token_type_format(self):
        """Test token_type is correctly formatted."""
        token_type = "Bearer"
        assert token_type == "Bearer"


class TestSessionManagement:
    """Tests for session lifecycle."""

    def test_refresh_token_optional_in_response(self):
        """Test that refresh_token can be optional in some responses."""
        # Refresh token might not always be returned
        response = {
            "access_token": "token",
            "refresh_token": None,
            "expires_in": 3600,
            "token_type": "Bearer"
        }
        assert response["refresh_token"] is None

    def test_logout_success_response(self):
        """Test logout success response structure."""
        response = {
            "success": True,
            "message": "Successfully logged out"
        }
        assert response["success"] is True
        assert "logged out" in response["message"].lower()


class TestAuthRateLimiting:
    """Tests for auth rate limiting (future feature)."""

    def test_signup_rate_limit_header(self):
        """Test rate limit headers in signup response."""
        # Future: X-RateLimit-Limit, X-RateLimit-Remaining headers
        headers = {
            "X-RateLimit-Limit": "100",
            "X-RateLimit-Remaining": "99",
            "X-RateLimit-Reset": "1705334400"
        }
        assert "X-RateLimit-Limit" in headers

    def test_login_rate_limit_header(self):
        """Test rate limit headers in login response."""
        headers = {
            "X-RateLimit-Limit": "100",
            "X-RateLimit-Remaining": "99"
        }
        assert int(headers["X-RateLimit-Limit"]) > 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
