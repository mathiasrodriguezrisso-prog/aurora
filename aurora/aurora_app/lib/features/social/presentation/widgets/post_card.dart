
import 'package:flutter/material.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../data/models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;
  final VoidCallback onLike;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: post.authorAvatar != null
                    ? NetworkImage(post.authorAvatar!)
                    : null,
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                child: post.authorAvatar == null
                    ? const Icon(Icons.person, color: AppTheme.primary)
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.authorUsername ?? 'Anonymous',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '2 hrs ago', // Placeholder date logic
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              if (post.techScore != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'TS: ${post.techScore}',
                    style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Content
          Text(
            post.content,
            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
          ),
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
             ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post.imageUrls.first, // Just showing first for MVP
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_,__,___) => Container(height: 200, color: Colors.grey[800], child: const Icon(Icons.error)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Actions
          Row(
            children: [
              _ActionButton(
                icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                label: '${post.likesCount}',
                color: post.isLiked ? AppTheme.error : Colors.white70,
                onTap: onLike,
              ),
              const SizedBox(width: 24),
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: '${post.commentsCount}',
                onTap: () {},
              ),
              const Spacer(),
              _ActionButton(icon: Icons.share_outlined, label: '', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
