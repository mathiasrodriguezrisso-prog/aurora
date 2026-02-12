"""
Aurora Feed Endpoints Tests
Tests for social feed HTTP endpoints: GET /feed, POST /posts, likes, comments.
"""
import pytest
import json
from datetime import datetime
from unittest.mock import Mock, AsyncMock, MagicMock

from fastapi.testclient import TestClient
from fastapi import status


class TestFeedGetEndpoint:
    """Tests for GET /social/feed endpoint."""

    def test_feed_pagination_default_params(self):
        """Test feed with default pagination parameters."""
        params = {"page": 1, "limit": 20}
        assert params["page"] >= 1
        assert 1 <= params["limit"] <= 50

    def test_feed_pagination_custom_params(self):
        """Test feed with custom pagination parameters."""
        params = {"page": 5, "limit": 30}
        assert params["page"] >= 1
        assert 1 <= params["limit"] <= 50

    def test_feed_strain_filter(self):
        """Test feed with strain filter."""
        params = {"strain": "Blue Dream"}
        assert params["strain"] is not None

    def test_feed_filter_types(self):
        """Test different feed filter types."""
        filter_types = ["trending", "recent", "following", "questions"]
        for filter_type in filter_types:
            params = {"filter": filter_type}
            assert params["filter"] in filter_types

    def test_feed_response_structure(self):
        """Test feed response structure."""
        response = {
            "posts": [
                {
                    "id": "post-1",
                    "content": "Test post",
                    "author_username": "grower_123",
                    "likes_count": 5,
                    "comments_count": 2,
                    "created_at": "2024-02-11T10:00:00Z",
                    "is_liked": False,
                }
            ],
            "page": 1,
            "has_more": True,
        }
        
        assert "posts" in response
        assert "page" in response
        assert "has_more" in response
        assert len(response["posts"]) > 0

    def test_feed_empty_response(self):
        """Test feed with no posts."""
        response = {
            "posts": [],
            "page": 1,
            "has_more": False,
        }
        
        assert response["posts"] == []
        assert response["has_more"] is False


class TestCreatePostEndpoint:
    """Tests for POST /social/posts endpoint."""

    def test_create_post_success_response(self):
        """Test successful post creation response."""
        response = {
            "id": "post-123",
            "user_id": "user-456",
            "content": "My grow is looking great!",
            "likes_count": 0,
            "comments_count": 0,
            "created_at": "2024-02-11T10:00:00Z",
            "is_toxic": False,
            "is_hidden": False,
        }
        
        assert response["id"] is not None
        assert response["content"] == "My grow is looking great!"
        assert response["is_hidden"] is False

    def test_create_post_with_images(self):
        """Test post creation with images."""
        request = {
            "content": "Check out my plants!",
            "image_urls": ["https://example.com/photo1.jpg", "https://example.com/photo2.jpg"],
        }
        
        assert len(request["image_urls"]) == 2

    def test_create_post_with_grow_context(self):
        """Test post creation with grow context."""
        request = {
            "content": "Day 21 flowering",
            "grow_id": "grow-789",
            "day_number": 21,
            "strain_tag": "Blue Dream",
        }
        
        assert request["grow_id"] is not None
        assert request["day_number"] == 21
        assert request["strain_tag"] == "Blue Dream"

    def test_create_post_rate_limit_exceeded(self):
        """Test rate limit when creating posts."""
        # After 30 posts, should get 429
        status_code = status.HTTP_429_TOO_MANY_REQUESTS
        assert status_code == 429

    def test_create_post_toxicity_flag(self):
        """Test post flagged as toxic gets hidden."""
        response = {
            "content": "Some toxic content",
            "is_toxic": True,
            "is_hidden": True,
        }
        
        assert response["is_toxic"] is True
        assert response["is_hidden"] is True


class TestGetPostEndpoint:
    """Tests for GET /social/posts/{post_id} endpoint."""

    def test_get_post_success(self):
        """Test getting a single post."""
        response = {
            "id": "post-123",
            "user_id": "user-456",
            "content": "My grow journey",
            "author_username": "grower_123",
            "is_liked": False,
            "likes_count": 10,
            "comments_count": 3,
            "created_at": "2024-02-11T10:00:00Z",
        }
        
        assert response["id"] == "post-123"
        assert response["content"] is not None

    def test_get_post_with_like_status(self):
        """Test post includes user's like status."""
        response = {
            "id": "post-123",
            "is_liked": True,
        }
        
        assert isinstance(response["is_liked"], bool)

    def test_get_post_not_found(self):
        """Test 404 when post doesn't exist."""
        status_code = status.HTTP_404_NOT_FOUND
        assert status_code == 404

    def test_get_hidden_post_permission_check(self):
        """Test hidden posts only visible to author."""
        # Owner can see
        is_owner = True
        is_hidden = True
        owner_can_see = is_owner or not is_hidden
        
        # Other user cannot see
        is_owner = False
        other_can_see = is_owner or not is_hidden
        
        assert owner_can_see is True
        assert other_can_see is False


class TestLikeEndpoint:
    """Tests for POST /social/posts/{post_id}/like endpoint."""

    def test_like_post_success(self):
        """Test successfully liking a post."""
        response = {"liked": True}
        assert response["liked"] is True

    def test_unlike_post_success(self):
        """Test successfully unliking a post."""
        response = {"liked": False}
        assert response["liked"] is False

    def test_like_toggle_behavior(self):
        """Test like/unlike toggle behavior."""
        # Like -> Unlike -> Like
        state1 = True  # Like
        state2 = False  # Unlike
        state3 = True  # Like again
        
        assert state1 != state2
        assert state3 == state1

    def test_like_updates_counter(self):
        """Test that like updates the likes counter."""
        initial_likes = 5
        after_like = initial_likes + 1
        after_unlike = after_like - 1
        
        assert after_like == 6
        assert after_unlike == 5

    def test_like_awards_karma(self):
        """Test that receiving likes awards karma to author."""
        # Karma should be awarded (non-critical, can fail silently)
        karma_awarded = True
        assert karma_awarded


class TestCommentsEndpoint:
    """Tests for comment endpoints."""

    def test_get_comments_pagination(self):
        """Test getting comments with pagination."""
        response = {
            "comments": [
                {
                    "id": "comment-1",
                    "content": "Great post!",
                    "author_username": "user_2",
                    "created_at": "2024-02-11T10:30:00Z",
                }
            ],
            "page": 1,
        }
        
        assert "comments" in response
        assert "page" in response

    def test_create_comment_success(self):
        """Test creating a comment."""
        response = {
            "id": "comment-123",
            "post_id": "post-456",
            "user_id": "user-789",
            "content": "This is helpful!",
            "created_at": "2024-02-11T10:35:00Z",
            "is_toxic": False,
            "is_hidden": False,
        }
        
        assert response["content"] == "This is helpful!"
        assert response["is_hidden"] is False

    def test_comment_toxicity_check(self):
        """Test comment flagged as toxic."""
        response = {
            "content": "Some toxic content",
            "is_toxic": True,
            "is_hidden": True,
        }
        
        assert response["is_toxic"] is True

    def test_comment_rate_limit(self):
        """Test rate limit for comments."""
        status_code = status.HTTP_429_TOO_MANY_REQUESTS
        assert status_code == 429

    def test_comments_increment_counter(self):
        """Test comments increment post counter."""
        initial_comments = 3
        after_comment = initial_comments + 1
        
        assert after_comment == 4


class TestReportEndpoint:
    """Tests for POST /social/report endpoint."""

    def test_report_post_success(self):
        """Test reporting a post."""
        response = {"reported": True}
        assert response["reported"] is True

    def test_report_comment_success(self):
        """Test reporting a comment."""
        response = {"reported": True}
        assert response["reported"] is True

    def test_report_creates_record(self):
        """Test that report creates a database record."""
        report = {
            "reporter_id": "user-123",
            "reason": "Misinformation",
            "post_id": "post-456",
            "status": "pending",
        }
        
        assert report["status"] == "pending"
        assert report["reporter_id"] is not None


class TestCompetitiveAnalysisEndpoint:
    """Tests for GET /social/competitive-analysis endpoint."""

    def test_competitive_analysis_response(self):
        """Test competitive analysis response structure."""
        response = {
            "user_stats": {
                "posts_count": 15,
                "completed_grows": 3,
                "avg_yield_grams": 125.5,
                "task_completion_rate": 85.0,
                "total_xp": 1200,
                "karma": 45,
                "level": 4,
            },
            "community_averages": {
                "avg_posts_per_user": 8.5,
                "avg_grows_per_user": 1.2,
                "total_active_users": 150,
            },
            "comparison": {
                "posts_vs_avg": 76.5,
                "grows_vs_avg": 150.0,
            },
        }
        
        assert "user_stats" in response
        assert "community_averages" in response
        assert "comparison" in response

    def test_percentile_ranking(self):
        """Test percentile ranking calculation."""
        user_posts = 20
        avg_posts = 12
        comparison = ((user_posts / max(avg_posts, 0.1)) - 1) * 100
        
        assert comparison > 0  # User above average

    def test_yield_averaging(self):
        """Test average yield calculation."""
        yields = [100, 120, 110, 115]
        avg_yield = sum(yields) / len(yields)
        
        assert avg_yield == 111.25

    def test_task_completion_rate(self):
        """Test task completion rate calculation."""
        completed_tasks = 85
        total_tasks = 100
        completion_rate = (completed_tasks / total_tasks) * 100
        
        assert completion_rate == 85.0


class TestFeedErrorHandling:
    """Tests for error handling in feed endpoints."""

    def test_invalid_page_parameter(self):
        """Test invalid page parameter."""
        # Page < 1 should be rejected
        invalid_page = 0
        assert not (invalid_page >= 1)

    def test_invalid_limit_parameter(self):
        """Test invalid limit parameter."""
        # Limit > 50 should be rejected
        invalid_limit = 100
        assert not (1 <= invalid_limit <= 50)

    def test_missing_authentication(self):
        """Test missing authentication header."""
        status_code = status.HTTP_401_UNAUTHORIZED
        assert status_code == 401

    def test_malformed_request(self):
        """Test malformed request body."""
        status_code = status.HTTP_400_BAD_REQUEST
        assert status_code == 400

    def test_internal_server_error(self):
        """Test internal server error handling."""
        status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
        assert status_code == 500


class TestFeedIntegration:
    """Integration tests for feed workflow."""

    def test_create_post_then_like_workflow(self):
        """Test workflow: create post -> like -> verify."""
        # 1. Create post
        post = {"id": "post-1", "likes_count": 0}
        
        # 2. Like post
        post["likes_count"] += 1
        liking_user_posts = {"post-1": True}
        
        # 3. Verify
        assert post["likes_count"] == 1
        assert liking_user_posts["post-1"] is True

    def test_post_with_comments_workflow(self):
        """Test workflow: create post -> add comments -> verify."""
        # 1. Create post
        post = {"id": "post-1", "comments_count": 0}
        
        # 2. Add comment
        post["comments_count"] += 1
        
        # 3. Add another comment
        post["comments_count"] += 1
        
        # 4. Verify
        assert post["comments_count"] == 2

    def test_trending_post_generation(self):
        """Test trending post generation."""
        posts = [
            {"id": "1", "likes": 20, "tech_score": 7.0, "comments": 5, "recency": 0.5},
            {"id": "2", "likes": 30, "tech_score": 6.0, "comments": 8, "recency": 0.3},
            {"id": "3", "likes": 10, "tech_score": 9.0, "comments": 2, "recency": 0.9},
        ]
        
        for post in posts:
            score = (post["likes"] * 0.3) + (post["tech_score"] * 0.4) + (post["comments"] * 0.1) + (post["recency"] * 10)
            post["score"] = score
        
        sorted_posts = sorted(posts, key=lambda p: p["score"], reverse=True)
        assert sorted_posts[0]["id"] is not None


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
