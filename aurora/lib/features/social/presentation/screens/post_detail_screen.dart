/// 📁 lib/features/social/presentation/screens/post_detail_screen.dart
/// Post detail screen with comments list + moderation visibility.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/config/app_theme.dart';
import '../../data/providers/social_providers.dart';
import '../../domain/entities/comment_entity.dart';
import '../widgets/post_card.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));
    final feedState = ref.watch(feedProvider);

    // Find the post from feed state
    final post = feedState.posts.where((p) => p.id == widget.postId).firstOrNull;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Post',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppTheme.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Post + Comments scrollable area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Post card
                if (post != null)
                  PostCard(
                    post: post,
                    onLike: () =>
                        ref.read(feedProvider.notifier).toggleLike(post.id),
                  ),

                const SizedBox(height: 16),

                // Comments header
                const Text(
                  'Comments',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Comments list
                commentsAsync.when(
                  data: (comments) {
                    if (comments.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  color: AppTheme.textTertiary, size: 40),
                              const SizedBox(height: 8),
                              const Text(
                                'No comments yet',
                                style: TextStyle(
                                  color: AppTheme.textTertiary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _CommentTile(comment: comments[index]),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                          color: AppTheme.primary),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Text(
                      'Error loading comments',
                      style: TextStyle(color: AppTheme.error),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Comment input bar
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        8,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: const Border(
          top: BorderSide(color: AppTheme.glassBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add a comment…',
                hintStyle: const TextStyle(
                    color: AppTheme.textTertiary, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppTheme.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppTheme.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                fillColor: AppTheme.glassBackground,
                filled: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _isSending
              ? const SizedBox(
                  width: 36,
                  height: 36,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.send_rounded,
                      color: AppTheme.primary),
                  onPressed: _sendComment,
                ),
        ],
      ),
    );
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() => _isSending = true);

    try {
      await ref
          .read(feedProvider.notifier)
          .addComment(widget.postId, text);
      _commentController.clear();
      // Refresh comments
      ref.invalidate(postCommentsProvider(widget.postId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send comment')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}

// ============================================
// Comment Tile with moderation visibility
// ============================================

class _CommentTile extends StatelessWidget {
  final CommentEntity comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final isToxic = comment.isToxic;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isToxic ? 0.3 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(
              color: isToxic
                  ? const Color(0xFFFFB800)
                  : Colors.transparent,
              width: isToxic ? 3 : 0,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                  backgroundImage: comment.authorAvatarUrl != null
                      ? CachedNetworkImageProvider(comment.authorAvatarUrl!)
                      : null,
                  child: comment.authorAvatarUrl == null
                      ? Text(
                          comment.authorUsername[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    comment.authorUsername,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  comment.timeAgo,
                  style: const TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 11,
                  ),
                ),
                // Toxic indicator tooltip
                if (isToxic)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Tooltip(
                      message: 'Flagged by AI moderation',
                      child: Icon(
                        Icons.flag_rounded,
                        size: 16,
                        color: const Color(0xFFFFB800),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Comment content (or hidden message)
            if (isToxic)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_off,
                        size: 14, color: AppTheme.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      'Comment hidden by AI moderation',
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                comment.content,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
