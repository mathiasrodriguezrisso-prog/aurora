/// User entity representing authenticated user data.
/// Pure domain object with no infrastructure dependencies.
class UserEntity {
  final String id;
  final String email;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final int level;
  final int xp;
  final int karma;
  final bool isPro;
  final String preferredLanguage;
  final int totalGrows;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.level = 1,
    this.xp = 0,
    this.karma = 0,
    this.isPro = false,
    this.preferredLanguage = 'en',
    this.totalGrows = 0,
    required this.createdAt,
  });

  /// Copy with method for immutability
  UserEntity copyWith({
    String? id,
    String? email,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    int? level,
    int? xp,
    int? karma,
    bool? isPro,
    String? preferredLanguage,
    int? totalGrows,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      karma: karma ?? this.karma,
      isPro: isPro ?? this.isPro,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      totalGrows: totalGrows ?? this.totalGrows,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
