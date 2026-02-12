
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../data/models/post_model.dart';
import '../../data/providers/social_providers.dart';
import '../widgets/post_card.dart';

class PostDetailScreen extends ConsumerWidget {
  final PostModel post;

  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(postCommentsProvider(post.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          PostCard(post: post, onTap: null, onLike: () {}), // Reuse PostCard
          Divider(color: AppTheme.glassBorder),
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return const Center(child: Text('No comments yet.', style: TextStyle(color: Colors.white54)));
                }
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: comment.authorAvatar != null
                            ? NetworkImage(comment.authorAvatar!)
                            : null,
                        child: comment.authorAvatar == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(comment.authorUsername ?? 'User', style: const TextStyle(color: Colors.white)),
                      subtitle: Text(comment.content, style: const TextStyle(color: Colors.white70)),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
