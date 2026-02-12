/// Entidad inmutable de Comentario.
library;

class CommentEntity {
  final String id;
  final String postId;
  final String authorId;
  final String authorUsername;
  final String? authorAvatarUrl;
  final String content;
  final bool isToxic;
  final DateTime createdAt;

  const CommentEntity({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorUsername,
    this.authorAvatarUrl,
    required this.content,
    this.isToxic = false,
    required this.createdAt,
  });

  /// Tiempo relativo desde la creación.
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}sem';
  }
}
