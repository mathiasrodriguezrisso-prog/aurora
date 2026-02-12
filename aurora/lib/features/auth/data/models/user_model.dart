import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../domain/entities/user_entity.dart';

/// User data model that handles JSON serialization.
/// Extends UserEntity for use in the data layer.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.username,
    super.displayName,
    super.avatarUrl,
    super.bio,
    super.level,
    super.xp,
    super.karma,
    super.isPro,
    super.preferredLanguage,
    super.totalGrows,
    required super.createdAt,
  });

  /// Create UserModel from Supabase Auth User + Profile data.
  factory UserModel.fromSupabaseAuth(supabase.User user, {Map<String, dynamic>? profile}) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      username: profile?['username'] ?? user.userMetadata?['username'],
      displayName: profile?['display_name'] ?? profile?['full_name'] ?? user.userMetadata?['display_name'] ?? user.userMetadata?['full_name'],
      avatarUrl: profile?['avatar_url'] ?? user.userMetadata?['avatar_url'],
      bio: profile?['bio'],
      level: profile?['level'] ?? 1,
      xp: profile?['xp'] ?? 0,
      karma: profile?['karma'] ?? 0,
      isPro: profile?['is_pro'] ?? false,
      preferredLanguage: profile?['preferred_language'] ?? 'en',
      totalGrows: profile?['total_grows'] ?? 0,
      createdAt: profile?['created_at'] != null
          ? DateTime.parse(profile!['created_at'])
          : DateTime.now(),
    );
  }

  /// Create UserModel from JSON (profile table).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'] ?? '',
      username: json['username'],
      displayName: json['display_name'] ?? json['full_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      karma: json['karma'] ?? 0,
      isPro: json['is_pro'] ?? false,
      preferredLanguage: json['preferred_language'] ?? 'en',
      totalGrows: json['total_grows'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// Convert to JSON for storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'level': level,
      'xp': xp,
      'karma': karma,
      'is_pro': isPro,
      'preferred_language': preferredLanguage,
      'total_grows': totalGrows,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
