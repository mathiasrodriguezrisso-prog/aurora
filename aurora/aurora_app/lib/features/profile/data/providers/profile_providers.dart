import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// User Model (Simple for Profile)
class UserProfile {
  final String id;
  final String displayName;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final int level;
  final int xp;
  final int karma;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.level = 1,
    this.xp = 0,
    this.karma = 0,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? fallbackEmail}) {
    return UserProfile(
      id: map['id']?.toString() ?? '',
      displayName: map['display_name']?.toString() ?? 'Grower',
      email: fallbackEmail ?? '',
      avatarUrl: map['avatar_url']?.toString(),
      bio: map['bio']?.toString(),
      level: (map['level'] as num?)?.toInt() ?? 1,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      karma: (map['karma'] as num?)?.toInt() ?? 0,
    );
  }
}

// Real Profile Provider (Supabase)
final userProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  if (user == null) {
    throw Exception('Not authenticated');
  }

  try {
    final data = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return UserProfile.fromMap(data, fallbackEmail: user.email);
  } catch (e) {
    // Fallback: return profile from auth metadata
    return UserProfile(
      id: user.id,
      displayName: user.userMetadata?['display_name']?.toString() ?? 'Grower',
      email: user.email ?? '',
      avatarUrl: null,
      bio: null,
      level: 1,
      xp: 0,
      karma: 0,
    );
  }
});

// Update Profile Provider
final updateProfileProvider = Provider<Future<void> Function(Map<String, dynamic>)>((ref) {
  return (Map<String, dynamic> data) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await client.from('profiles').update(data).eq('id', userId);
    ref.invalidate(userProfileProvider);
  };
});

// Settings Provider
class SettingsState {
  final bool pushEnabled;
  final bool darkMode;

  SettingsState({this.pushEnabled = true, this.darkMode = true});

  SettingsState copyWith({bool? pushEnabled, bool? darkMode}) {
    return SettingsState(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState());

  void togglePush(bool value) => state = state.copyWith(pushEnabled: value);
  void toggleTheme(bool value) => state = state.copyWith(darkMode: value);
}
