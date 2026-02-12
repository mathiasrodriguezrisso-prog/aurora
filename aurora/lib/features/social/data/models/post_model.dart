/// Modelos de datos para Post y Comment.
/// Extienden las entidades del dominio y agregan fromJson/toJson.
library;

import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/post_entity.dart';
import 'grow_snapshot_model.dart';

// ─────────────────────────────────────────────────────
// PostModel
// ─────────────────────────────────────────────────────

class PostModel extends PostEntity {
  const PostModel({
    required super.id,
    required super.authorId,
    required super.authorUsername,
    super.authorAvatarUrl,
    required super.authorLevel,
    required super.content,
    super.imageUrls,
    required super.category,
    super.growId,
    super.growSnapshot,
    super.techScore,
    super.likesCount,
    super.commentsCount,
    super.isLiked,
    required super.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Parsear grow_snapshot si existe
    GrowSnapshotModel? snapshot;
    if (json['grow_snapshot'] != null && json['grow_snapshot'] is Map) {
      snapshot = GrowSnapshotModel.fromJson(
          json['grow_snapshot'] as Map<String, dynamic>);
    }

    return PostModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String? ?? '',
      authorUsername: json['author_username'] as String? ?? 'Grower',
      authorAvatarUrl: json['author_avatar_url'] as String?,
      authorLevel: json['author_level'] as int? ?? 1,
      content: json['content'] as String? ?? '',
      imageUrls: (json['image_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      category: json['category'] as String? ?? 'showcase',
      growId: json['grow_id'] as String?,
      growSnapshot: snapshot,
      techScore: (json['tech_score'] as num?)?.toDouble() ?? 0.0,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'category': category,
      'image_urls': imageUrls,
      if (growId != null) 'grow_id': growId,
    };
  }

  /// Convierte un PostEntity a PostModel (para optimistic updates).
  factory PostModel.fromEntity(PostEntity entity) {
    return PostModel(
      id: entity.id,
      authorId: entity.authorId,
      authorUsername: entity.authorUsername,
      authorAvatarUrl: entity.authorAvatarUrl,
      authorLevel: entity.authorLevel,
      content: entity.content,
      imageUrls: entity.imageUrls,
      category: entity.category,
      growId: entity.growId,
      growSnapshot: entity.growSnapshot,
      techScore: entity.techScore,
      likesCount: entity.likesCount,
      commentsCount: entity.commentsCount,
      isLiked: entity.isLiked,
      createdAt: entity.createdAt,
    );
  }

  /// copyWith override que retorna PostModel.
  @override
  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorUsername,
    String? authorAvatarUrl,
    int? authorLevel,
    String? content,
    List<String>? imageUrls,
    String? category,
    String? growId,
    dynamic growSnapshot,
    double? techScore,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    DateTime? createdAt,
  }) {
    return PostModel(
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
}

// ─────────────────────────────────────────────────────
// CommentModel
// ─────────────────────────────────────────────────────

class CommentModel extends CommentEntity {
  const CommentModel({
    required super.id,
    required super.postId,
    required super.authorId,
    required super.authorUsername,
    super.authorAvatarUrl,
    required super.content,
    super.isToxic,
    required super.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      postId: json['post_id'] as String? ?? '',
      authorId: json['author_id'] as String? ?? '',
      authorUsername: json['author_username'] as String? ?? 'Grower',
      authorAvatarUrl: json['author_avatar_url'] as String?,
      content: json['content'] as String? ?? '',
      isToxic: json['is_toxic'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }
}
