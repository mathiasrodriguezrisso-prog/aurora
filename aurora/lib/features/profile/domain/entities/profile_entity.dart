/// 📁 lib/features/profile/domain/entities/profile_entity.dart

class ProfileEntity {
  final String id;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final String experienceLevel;
  final String? growStyle;
  final int karma;
  final bool isFollowing;

  const ProfileEntity({
    required this.id,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.location,
    required this.experienceLevel,
    this.growStyle,
    required this.karma,
    this.isFollowing = false,
  });

  ProfileEntity copyWith({
    String? id,
    String? displayName,
    String? username,
    String? avatarUrl,
    String? bio,
    String? location,
    String? experienceLevel,
    String? growStyle,
    int? karma,
    bool? isFollowing,
  }) {
    return ProfileEntity(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      growStyle: growStyle ?? this.growStyle,
      karma: karma ?? this.karma,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}
