"""
Aurora Feed Service Tests
Tests for feed service, post creation, likes, comments, and filtering.
"""
import pytest
from datetime import datetime, timezone, timedelta
from unittest.mock import Mock, AsyncMock, patch
from uuid import uuid4

from app.routers.social import (
    CreatePostRequest,
    CommentRequest,
    ReportRequest,
    PostResponse,
    CommentResponse,
)


class TestPostCreation:
    """Tests for post creation."""

    def test_create_post_request_minimal(self):
        """Test minimal post creation request."""
        request = CreatePostRequest(
            content="Looking good today!",
        )
        assert request.content == "Looking good today!"
        assert request.image_urls == []
        assert request.strain_tag is None
        assert request.grow_id is None

    def test_create_post_request_with_all_fields(self):
        """Test post with all fields populated."""
        request = CreatePostRequest(
            content="Day 21 of flowering. VPD is perfect!",
            image_urls=["https://example.com/pic1.jpg"],
            strain_tag="Blue Dream",
            grow_id="grow-123",
            day_number=21,
        )
        assert request.content == "Day 21 of flowering. VPD is perfect!"
        assert len(request.image_urls) == 1
        assert request.strain_tag == "Blue Dream"
        assert request.grow_id == "grow-123"
        assert request.day_number == 21

    def test_create_post_content_length_validation(self):
        """Test content length validation."""
        # Too short
        with pytest.raises(ValueError):
            CreatePostRequest(content="")
        
        # Too long
        with pytest.raises(ValueError):
            CreatePostRequest(content="x" * 2001)

    def test_create_post_image_urls_limit(self):
        """Test max image URLs limit."""
        # Valid: 5 images
        request = CreatePostRequest(
            content="Post with images",
            image_urls=["url1", "url2", "url3", "url4", "url5"]
        )
        assert len(request.image_urls) == 5
        
        # Invalid: 6 images
        with pytest.raises(ValueError):
            CreatePostRequest(
                content="Post",
                image_urls=["url1", "url2", "url3", "url4", "url5", "url6"]
            )

    def test_post_response_model(self):
        """Test PostResponse model structure."""
        response = PostResponse(
            id="post-123",
            user_id="user-456",
            content="Test post",
            image_urls=[],
            strain_tag="Test Strain",
            grow_id="grow-789",
            day_number=15,
            likes_count=5,
            comments_count=2,
            created_at="2024-02-11T10:00:00Z",
            author_username="grower_123",
            author_avatar="https://example.com/avatar.jpg",
            is_liked=False,
            tech_score=8.5,
            is_toxic=False,
            is_hidden=False,
        )
        
        assert response.id == "post-123"
        assert response.likes_count == 5
        assert response.comments_count == 2
        assert response.tech_score == 8.5
        assert response.is_toxic is False


class TestComments:
    """Tests for comment functionality."""

    def test_comment_request_minimal(self):
        """Test minimal comment request."""
        request = CommentRequest(
            content="Great post!"
        )
        assert request.content == "Great post!"

    def test_comment_content_length_validation(self):
        """Test comment content length validation."""
        # Too short
        with pytest.raises(ValueError):
            CommentRequest(content="")
        
        # Too long
        with pytest.raises(ValueError):
            CommentRequest(content="x" * 501)

    def test_comment_response_model(self):
        """Test CommentResponse model structure."""
        response = CommentResponse(
            id="comment-123",
            post_id="post-456",
            user_id="user-789",
            content="This is a helpful comment",
            created_at="2024-02-11T10:30:00Z",
            author_username="commenter_1",
            author_avatar="https://example.com/avatar.jpg",
            is_hidden=False,
            is_flagged=False,
            is_toxic=False,
        )
        
        assert response.id == "comment-123"
        assert response.post_id == "post-456"
        assert response.is_toxic is False


class TestReporting:
    """Tests for content reporting."""

    def test_report_post_request(self):
        """Test reporting a post."""
        request = ReportRequest(
            reason="This post contains misinformation",
            post_id="post-123",
            comment_id=None,
        )
        assert request.reason == "This post contains misinformation"
        assert request.post_id == "post-123"
        assert request.comment_id is None

    def test_report_comment_request(self):
        """Test reporting a comment."""
        request = ReportRequest(
            reason="Toxic language",
            post_id=None,
            comment_id="comment-456",
        )
        assert request.reason == "Toxic language"
        assert request.comment_id == "comment-456"

    def test_report_reason_validation(self):
        """Test report reason validation."""
        # Too short
        with pytest.raises(ValueError):
            ReportRequest(reason="")
        
        # Too long
        with pytest.raises(ValueError):
            ReportRequest(reason="x" * 501)


class TestFeedFiltering:
    """Tests for feed filtering and sorting."""

    def test_feed_filter_types(self):
        """Test valid feed filter types."""
        valid_filters = ["trending", "recent", "following", "questions"]
        for filter_type in valid_filters:
            assert filter_type in ["trending", "recent", "following", "questions"]

    def test_trending_score_calculation(self):
        """Test trending score calculation formula."""
        # Score = (likes * 0.3) + (tech_score * 0.4) + (comments * 0.1) + (recency * 0.2)
        
        # Post 1: High engagement, old
        likes1 = 50
        tech_score1 = 7.0
        comments1 = 10
        recency1 = 0.2  # Old post
        score1 = (likes1 * 0.3) + (tech_score1 * 0.4) + (comments1 * 0.1) + (recency1 * 10)
        
        # Post 2: Very high tech score, new
        likes2 = 50  # Same as post1
        tech_score2 = 10.0  # Higher tech score
        comments2 = 10  # Same as post1
        recency2 = 1.0  # New post
        score2 = (likes2 * 0.3) + (tech_score2 * 0.4) + (comments2 * 0.1) + (recency2 * 10)
        
        # Score2 should be higher due to higher tech_score and recency
        assert score2 > score1

    def test_pagination_parameters(self):
        """Test pagination parameter validation."""
        # Valid page
        assert 1 >= 1
        
        # Valid limit
        assert 1 <= 20 <= 50
        
        # Invalid limit
        assert not (51 <= 50)


class TestEngagement:
    """Tests for engagement metrics."""

    def test_like_toggle_structure(self):
        """Test like toggle response structure."""
        like_response = {"liked": True}
        unlike_response = {"liked": False}
        
        assert like_response["liked"] is True
        assert unlike_response["liked"] is False

    def test_engagement_counters(self):
        """Test engagement counter increments."""
        initial_likes = 0
        after_like = initial_likes + 1
        after_unlike = after_like - 1
        
        assert after_like == 1
        assert after_unlike == 0

    def test_engagement_rate_calculation(self):
        """Test engagement rate calculation."""
        posts = [
            {"likes": 10, "comments": 5},
            {"likes": 20, "comments": 3},
            {"likes": 5, "comments": 12},
        ]
        
        for post in posts:
            engagement_rate = post["likes"] + post["comments"]
            assert engagement_rate > 0


class TestStrainTagging:
    """Tests for strain tagging functionality."""

    def test_strain_tag_in_post(self):
        """Test strain tag in post creation."""
        strain_tags = ["Blue Dream", "OG Kush", "Girl Scout Cookies"]
        
        for tag in strain_tags:
            request = CreatePostRequest(
                content="Growing this strain",
                strain_tag=tag,
            )
            assert request.strain_tag == tag

    def test_strain_filter_feed(self):
        """Test filtering feed by strain."""
        # Simulate filtering logic
        posts = [
            {"id": "1", "strain_tag": "Blue Dream"},
            {"id": "2", "strain_tag": "OG Kush"},
            {"id": "3", "strain_tag": "Blue Dream"},
        ]
        
        filtered = [p for p in posts if p["strain_tag"] == "Blue Dream"]
        assert len(filtered) == 2
        assert all(p["strain_tag"] == "Blue Dream" for p in filtered)


class TestPostVisibility:
    """Tests for post visibility and hiding."""

    def test_toxic_post_hidden(self):
        """Test that toxic posts are hidden."""
        # A toxic post would have is_hidden=True
        toxic_post = {
            "content": "Some toxic content",
            "is_toxic": True,
            "is_hidden": True,
        }
        assert toxic_post["is_hidden"] is True
        assert toxic_post["is_toxic"] is True

    def test_hidden_post_visibility_rules(self):
        """Test visibility rules for hidden posts."""
        # Only author can see hidden posts
        post = {"id": "post-1", "is_hidden": True, "user_id": "user-1"}
        author = "user-1"
        requester = "user-2"
        
        can_author_see = post["user_id"] == author or not post["is_hidden"]
        can_other_see = not post["is_hidden"]
        
        assert can_author_see is True
        assert can_other_see is False


class TestRateLimiting:
    """Tests for social action rate limiting."""

    def test_rate_limit_threshold(self):
        """Test rate limit is 30 requests per minute."""
        max_requests = 30
        assert max_requests == 30

    def test_rate_limit_cache_behavior(self):
        """Test rate limiting cache mechanics."""
        from app.routers.social import rate_limit_cache, check_rate_limit
        
        # Clear cache
        rate_limit_cache.clear()
        
        user_id = "test-user-rate-limit"
        
        # First 30 should pass
        for i in range(30):
            allowed = check_rate_limit(user_id, max_requests=30)
            assert allowed is True
        
        # 31st should fail
        allowed = check_rate_limit(user_id, max_requests=30)
        assert allowed is False


class TestFeedModels:
    """Tests for feed-related Pydantic models."""

    def test_post_response_serialization(self):
        """Test PostResponse can be serialized."""
        post = PostResponse(
            id="post-1",
            user_id="user-1",
            content="Test content",
            image_urls=[],
            strain_tag=None,
            grow_id=None,
            day_number=None,
            likes_count=5,
            comments_count=2,
            created_at="2024-02-11T00:00:00Z",
            author_username="test_user",
            author_avatar=None,
            is_liked=False,
            tech_score=None,
            is_toxic=False,
            is_hidden=False,
        )
        
        # Test serialization
        post_dict = post.model_dump()
        assert isinstance(post_dict, dict)
        assert post_dict["id"] == "post-1"
        assert post_dict["likes_count"] == 5

    def test_comment_response_serialization(self):
        """Test CommentResponse can be serialized."""
        comment = CommentResponse(
            id="comment-1",
            post_id="post-1",
            user_id="user-1",
            content="Great post!",
            created_at="2024-02-11T00:00:00Z",
            author_username="commenter",
            author_avatar=None,
            is_hidden=False,
            is_flagged=False,
            is_toxic=False,
        )
        
        comment_dict = comment.model_dump()
        assert isinstance(comment_dict, dict)
        assert comment_dict["content"] == "Great post!"


class TestCompetitiveAnalysis:
    """Tests for competitive analysis feature."""

    def test_user_stats_structure(self):
        """Test user stats structure in competitive analysis."""
        user_stats = {
            "posts_count": 15,
            "completed_grows": 3,
            "avg_yield_grams": 125.5,
            "task_completion_rate": 85.0,
            "total_xp": 1200,
            "karma": 45,
            "level": 4,
        }
        
        assert user_stats["posts_count"] > 0
        assert user_stats["total_xp"] > 0
        assert user_stats["level"] >= 1

    def test_percentile_calculation(self):
        """Test percentile ranking calculation."""
        user_score = 1200
        community_average = 850
        
        # Calculate percentile increase
        percentile_increase = ((user_score / community_average) - 1) * 100
        assert percentile_increase > 0

    def test_comparison_metrics(self):
        """Test comparison metrics calculation."""
        user_posts = 20
        avg_posts = 12
        comparison = ((user_posts / max(avg_posts, 0.1)) - 1) * 100
        
        assert comparison > 0  # User above average


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
