class PostModel {
  final String id;
  final String userId;
  final String content;
  final List<String> imageUrls;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final String? authorUsername;
  final String? authorAvatar;
  final bool isLiked;
  final String? strainTag;
  final int? dayNumber;
  final double? techScore;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.imageUrls,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    this.authorUsername,
    this.authorAvatar,
    this.isLiked = false,
    this.strainTag,
    this.dayNumber,
    this.techScore,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Handle the joined profiles data from Supabase
    final profiles = json['profiles'] as Map<String, dynamic>?;

    // Handle image_urls which could be a List or null
    List<String> parseImageUrls(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return PostModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      imageUrls: parseImageUrls(json['image_urls']),
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      authorUsername: profiles?['display_name']?.toString() ?? json['author_username']?.toString(),
      authorAvatar: profiles?['avatar_url']?.toString() ?? json['author_avatar']?.toString(),
      isLiked: json['is_liked'] as bool? ?? false,
      strainTag: json['strain_tag']?.toString(),
      dayNumber: (json['day_number'] as num?)?.toInt(),
      techScore: (json['tech_score'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'image_urls': imageUrls,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'created_at': createdAt.toIso8601String(),
      'author_username': authorUsername,
      'author_avatar': authorAvatar,
      'is_liked': isLiked,
      'strain_tag': strainTag,
      'day_number': dayNumber,
      'tech_score': techScore,
    };
  }

  PostModel copyWith({
    bool? isLiked,
    int? likesCount,
    int? commentsCount,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      content: content,
      imageUrls: imageUrls,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt,
      authorUsername: authorUsername,
      authorAvatar: authorAvatar,
      isLiked: isLiked ?? this.isLiked,
      strainTag: strainTag,
      dayNumber: dayNumber,
      techScore: techScore,
    );
  }
}
