/// 📁 lib/features/social/presentation/widgets/post_card.dart
/// Reusable post card for the social feed with image carousel,
/// like/comment actions, Grow-Linked bar, category badge, and Tech Score badge.
library;

import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_theme.dart';
import '../../data/models/post_model.dart';
import '../../domain/entities/grow_snapshot_entity.dart';
import 'grow_linked_bar.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback? onComment;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/pulse/post/${post.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author header + category badge
                _buildAuthorRow(context),

                // Content
                if (post.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      post.content,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Images with Grow-Linked bar + Tech Score badge
                if (post.imageUrls.isNotEmpty) _buildImages(),

                // Tags (shown below content if no images)
                if (post.imageUrls.isEmpty && post.growSnapshot != null)
                  _buildInlineTags(),

                // Actions
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.3),
                backgroundImage: post.authorAvatarUrl != null
                    ? CachedNetworkImageProvider(post.authorAvatarUrl!)
                    : null,
                child: post.authorAvatarUrl == null
                    ? Text(
                        post.authorUsername[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              // Level badge
              Positioned(
                bottom: -2,
                right: -4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${post.authorLevel}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.authorUsername,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      post.timeAgo,
                      style: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _categoryBadge(post.category),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz,
                color: AppTheme.textTertiary, size: 20),
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
    );
  }

  Widget _categoryBadge(String category) {
    Color color;
    String label;
    switch (category) {
      case 'question':
        color = AppTheme.secondary;
        label = '❓ Question';
        break;
      case 'tutorial':
        color = AppTheme.warning;
        label = '📘 Tutorial';
        break;
      case 'diary':
        color = const Color(0xFF9B59B6);
        label = '📖 Diary';
        break;
      default: // 'showcase'
        color = AppTheme.primary;
        label = '🌟 Showcase';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildImages() {
    final bool hasTechScore = post.techScore > 0;
    final GrowSnapshotEntity? snapshot = post.growSnapshot;

    if (post.imageUrls.length == 1) {
      return Stack(
        children: [
          ClipRRect(
            child: CachedNetworkImage(
              imageUrl: post.imageUrls.first,
              height: 280,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 280,
                color: AppTheme.glassBackground,
                child: const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 200,
                color: AppTheme.glassBackground,
                child: const Icon(Icons.image_outlined,
                    color: AppTheme.textTertiary, size: 48),
              ),
            ),
          ),
          // Grow-Linked Bar — bottom overlay
          if (snapshot != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GrowLinkedBar(snapshot: snapshot),
            ),
          // Tech Score Badge — top-right
          if (hasTechScore)
            Positioned(
              top: 8,
              right: 8,
              child: _buildTechScoreBadge(),
            ),
        ],
      );
    }

    // Multiple images: horizontal carousel
    return SizedBox(
      height: 240,
      child: Stack(
        children: [
          ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: post.imageUrls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: post.imageUrls[index],
                  width: 200,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 200,
                    color: AppTheme.glassBackground,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primary, strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 200,
                    color: AppTheme.glassBackground,
                    child: const Icon(Icons.image_outlined,
                        color: AppTheme.textTertiary),
                  ),
                ),
              );
            },
          ),
          // Tech Score Badge — top-right over carousel
          if (hasTechScore)
            Positioned(
              top: 8,
              right: 24,
              child: _buildTechScoreBadge(),
            ),
        ],
      ),
    );
  }

  /// Tech Score circle badge displayed top-right of the image.
  Widget _buildTechScoreBadge() {
    final score = post.techScore;
    final Color bgColor;
    final Color textColor;

    if (score > 7) {
      bgColor = const Color(0xFF00FF88);
      textColor = Colors.black87;
    } else if (score >= 4) {
      bgColor = const Color(0xFFFFB800);
      textColor = Colors.black87;
    } else {
      bgColor = const Color(0xFF8B8BA3);
      textColor = Colors.white;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Text(
          score.toInt().toString(),
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInlineTags() {
    final snapshot = post.growSnapshot;
    if (snapshot == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 6,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '🌿 ${snapshot.strain}',
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.textTertiary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Week ${snapshot.week}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Like
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onLike();
            },
            child: Row(
              children: [
                Icon(
                  post.isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 22,
                  color: post.isLiked ? Colors.red : AppTheme.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.likesCount}',
                  style: TextStyle(
                    color: post.isLiked ? Colors.red : AppTheme.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Comment
          GestureDetector(
            onTap:
                onComment ?? () => context.push('/pulse/post/${post.id}'),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.commentsCount}',
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Share
          const Icon(
            Icons.share_outlined,
            size: 20,
            color: AppTheme.textTertiary,
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined,
                  color: AppTheme.textSecondary),
              title: const Text('Report',
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading:
                  const Icon(Icons.block, color: AppTheme.textSecondary),
              title: const Text('Hide post',
                  style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
