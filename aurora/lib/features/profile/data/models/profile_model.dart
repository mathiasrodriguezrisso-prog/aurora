/// 📁 lib/features/profile/data/models/profile_model.dart

import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.displayName,
    required super.username,
    super.avatarUrl,
    super.bio,
    super.location,
    required super.experienceLevel,
    super.growStyle,
    required super.karma,
    super.isFollowing,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.growsCount = 0,
  });

  final int followersCount;
  final int followingCount;
  final int postsCount;
  final int growsCount;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? json['username'] as String? ?? 'Grower',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      experienceLevel: json['experience_level'] as String? ?? 'beginner',
      growStyle: json['grow_style'] as String?,
      karma: (json['karma'] as num?)?.toInt() ?? 0,
      isFollowing: json['is_following'] as bool? ?? false,
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      postsCount: (json['posts_count'] as num?)?.toInt() ?? 0,
      growsCount: (json['grows_count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'display_name': displayName,
      'username': username,
      'avatar_url': avatarUrl,
      'bio': bio,
      'location': location,
      'experience_level': experienceLevel,
      'grow_style': growStyle,
    };
  }
}
