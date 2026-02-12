/// Entidad inmutable de Post.
library;

import 'grow_snapshot_entity.dart';

class PostEntity {
  final String id;
  final String authorId;
  final String authorUsername;
  final String? authorAvatarUrl;
  final int authorLevel;
  final String content;
  final List<String> imageUrls;
  final String category; // 'showcase', 'question', 'tutorial', 'diary'
  final String? growId;
  final GrowSnapshotEntity? growSnapshot;
  final double techScore;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime createdAt;

  const PostEntity({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    this.authorAvatarUrl,
    required this.authorLevel,
    required this.content,
    this.imageUrls = const [],
    required this.category,
    this.growId,
    this.growSnapshot,
    this.techScore = 0.0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    required this.createdAt,
  });

  PostEntity copyWith({
    String? id,
    String? authorId,
    String? authorUsername,
    String? authorAvatarUrl,
    int? authorLevel,
    String? content,
    List<String>? imageUrls,
    String? category,
    String? growId,
    GrowSnapshotEntity? growSnapshot,
    double? techScore,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    DateTime? createdAt,
  }) {
    return PostEntity(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorLevel: authorLevel ?? this.authorLevel,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      growId: growId ?? this.growId,
      growSnapshot: growSnapshot ?? this.growSnapshot,
      techScore: techScore ?? this.techScore,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Tiempo relativo desde la creación.
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}sem';
    return '${(diff.inDays / 30).floor()}mes';
  }
}
