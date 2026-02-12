/// 📁 lib/features/profile/data/providers/profile_providers.dart
/// Providers de Riverpod para gestionar el perfil del usuario,
/// estadísticas, logros y configuración.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/services/image_upload_service.dart';
import '../../../../core/network/api_client.dart';
import '../datasources/profile_remote_data_source.dart';
import '../repositories/profile_repository_impl.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/profile_stats_entity.dart';
import '../../domain/entities/achievement_entity.dart';
import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/get_my_profile.dart';
import '../../../social/domain/entities/post_entity.dart';
import '../../domain/usecases/get_profile_stats.dart';
import '../../domain/usecases/get_user_profile.dart';
import '../../domain/usecases/update_profile.dart';

// ===========================================
// DEPENDENCY INJECTION
// ===========================================

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider));
});

final getMyProfileProvider = Provider<GetMyProfile>((ref) {
  return GetMyProfile(ref.watch(profileRepositoryProvider));
});

final getUserProfileProvider = Provider<GetUserProfile>((ref) {
  return GetUserProfile(ref.watch(profileRepositoryProvider));
});

final getProfileStatsProvider = Provider<GetProfileStats>((ref) {
  return GetProfileStats(ref.watch(profileRepositoryProvider));
});

final updateProfileUsecaseProvider = Provider<UpdateProfile>((ref) {
  return UpdateProfile(ref.watch(profileRepositoryProvider));
});

// ===========================================
// PROFILE STATE
// ===========================================

class ProfileState {
  final ProfileEntity? myProfile;
  final ProfileStatsEntity? myStats;
  final List<AchievementEntity> achievements;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.myProfile,
    this.myStats,
    this.achievements = const [],
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    ProfileEntity? myProfile,
    ProfileStatsEntity? myStats,
    List<AchievementEntity>? achievements,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      myProfile: myProfile ?? this.myProfile,
      myStats: myStats ?? this.myStats,
      achievements: achievements ?? this.achievements,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final GetMyProfile _getMyProfile;
  final GetProfileStats _getProfileStats;
  final UpdateProfile _updateProfile;
  final ImageUploadService _imageUploadService;
  final ProfileRepository _profileRepository;
 
  ProfileNotifier(
    this._getMyProfile,
    this._getProfileStats,
    this._updateProfile,
    this._imageUploadService,
    this._profileRepository,
  ) : super(const ProfileState());

  Future<void> loadMyProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getMyProfile();
    
    await result.fold(
      (failure) async => state = state.copyWith(isLoading: false, error: failure.message),
      (profile) async {
        final statsResult = await _getProfileStats(profile.id);
        final achievementsResult = await _profileRepository.getAchievements(profile.id);
        
        final stats = statsResult.getRight().toNullable();
        final achievements = achievementsResult.getRight().toNullable() ?? [];

        state = state.copyWith(
          myProfile: profile,
          myStats: stats,
          achievements: achievements,
          isLoading: false,
        );
      },
    );
  }

  Future<bool> updateProfile({
    String? displayName,
    String? bio,
    String? location,
    String? growStyle,
    String? experienceLevel,
    String? avatarUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _updateProfile(
      displayName: displayName,
      bio: bio,
      location: location,
      growStyle: growStyle,
      experienceLevel: experienceLevel,
      avatarUrl: avatarUrl,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (profile) {
        state = state.copyWith(myProfile: profile, isLoading: false);
        return true;
      },
    );
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final notifier = ProfileNotifier(
    ref.watch(getMyProfileProvider),
    ref.watch(getProfileStatsProvider),
    ref.watch(updateProfileUsecaseProvider),
    ref.watch(imageUploadServiceProvider),
    ref.watch(profileRepositoryProvider),
  );
  notifier.loadMyProfile();
  return notifier;
});

// ===========================================
// PUBLIC PROFILE
// ===========================================

class PublicProfileState {
  final ProfileEntity? profile;
  final ProfileStatsEntity? stats;
  final List<PostEntity> posts;
  final bool isLoading;
  final String? error;

  const PublicProfileState({
    this.profile,
    this.stats,
    this.achievements = const [],
    this.posts = const [],
    this.isLoading = false,
    this.error,
  });

  PublicProfileState copyWith({
    ProfileEntity? profile,
    ProfileStatsEntity? stats,
    List<AchievementEntity>? achievements,
    List<PostEntity>? posts,
    bool? isLoading,
    String? error,
  }) {
    return PublicProfileState(
      profile: profile ?? this.profile,
      stats: stats ?? this.stats,
      achievements: achievements ?? this.achievements,
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PublicProfileNotifier extends StateNotifier<PublicProfileState> {
  final GetUserProfile _getUserProfile;
  final GetProfileStats _getProfileStats;
  final ProfileRepository _profileRepository;
  final String userId;

  PublicProfileNotifier(
    this._getUserProfile,
    this._getProfileStats,
    this._profileRepository,
    this.userId,
  ) : super(const PublicProfileState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getUserProfile(userId);
    
    await result.fold(
      (failure) async => state = state.copyWith(isLoading: false, error: failure.message),
      (profile) async {
        final statsResult = await _getProfileStats(userId);
        final postsResult = await _profileRepository.getUserPosts(userId);
        final achievementsResult = await _profileRepository.getAchievements(userId);
        
        final stats = statsResult.getRight().toNullable();
        final posts = postsResult.getRight().toNullable() ?? [];
        final achievements = achievementsResult.getRight().toNullable() ?? [];
        
        state = state.copyWith(
          profile: profile,
          stats: stats,
          posts: posts,
          achievements: achievements,
          isLoading: false,
        );
      },
    );
  }

  Future<void> toggleFollow() async {
    if (state.profile == null) return;
    
    final isCurrentlyFollowing = state.profile!.isFollowing;
    
    // Optimistic update
    state = state.copyWith(
      profile: state.profile!.copyWith(isFollowing: !isCurrentlyFollowing),
    );

    final result = isCurrentlyFollowing 
      ? await _profileRepository.unfollowUser(userId)
      : await _profileRepository.followUser(userId);

    result.fold(
      (failure) {
        state = state.copyWith(
          profile: state.profile!.copyWith(isFollowing: isCurrentlyFollowing),
        );
      },
      (_) => null,
    );
  }
}

final publicProfileProvider = StateNotifierProvider.family<PublicProfileNotifier, PublicProfileState, String>((ref, userId) {
  final notifier = PublicProfileNotifier(
    ref.watch(getUserProfileProvider),
    ref.watch(getProfileStatsProvider),
    ref.watch(profileRepositoryProvider),
    userId,
  );
  notifier.loadProfile();
  return notifier;
});

// ===========================================
// SETTINGS
// ===========================================

class SettingsState {
  final SettingsEntity settings;
  final bool isLoading;

  const SettingsState({
    this.settings = const SettingsEntity(),
    this.isLoading = false,
  });

  SettingsState copyWith({
    SettingsEntity? settings,
    bool? isLoading,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final ApiClient _api;
  SettingsNotifier(this._api) : super(const SettingsState());

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _api.get('/users/me/settings');
      if (response.data != null) {
        state = state.copyWith(
          settings: SettingsEntity.fromJson(response.data as Map<String, dynamic>),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateSetting(String key, dynamic value) async {
    final Map<String, dynamic> currentJson = state.settings.toJson();
    currentJson[key] = value;
    final updatedEntity = SettingsEntity.fromJson(currentJson);
    final previousState = state;
    
    state = state.copyWith(settings: updatedEntity);

    try {
      await _api.patch('/users/me/settings', data: {key: value});
    } catch (e) {
      state = previousState;
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final notifier = SettingsNotifier(ref.watch(apiClientProvider));
  notifier.loadSettings();
  return notifier;
});
