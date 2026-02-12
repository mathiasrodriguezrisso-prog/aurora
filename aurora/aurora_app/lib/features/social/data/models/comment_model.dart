class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? authorUsername;
  final String? authorAvatar;
  final bool isHidden;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorUsername,
    this.authorAvatar,
    this.isHidden = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // Handle the joined profiles data from Supabase
    final profiles = json['profiles'] as Map<String, dynamic>?;

    return CommentModel(
      id: json['id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      authorUsername: profiles?['display_name']?.toString() ?? json['author_username']?.toString(),
      authorAvatar: profiles?['avatar_url']?.toString() ?? json['author_avatar']?.toString(),
      isHidden: json['is_hidden'] as bool? ?? false,
    );
  }
}
