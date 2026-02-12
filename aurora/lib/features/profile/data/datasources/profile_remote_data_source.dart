/// 📁 lib/features/profile/data/datasources/profile_remote_data_source.dart

import '../../../../core/network/api_client.dart';
import '../models/profile_model.dart';
import '../models/achievement_model.dart';
import '../models/gamification_stats_model.dart';
import '../../../social/data/models/post_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getMyProfile();
  Future<ProfileModel> getUserProfile(String userId);
  Future<Map<String, dynamic>> getProfileStats(String userId);
  Future<ProfileModel> updateProfile(Map<String, dynamic> fields);
  Future<void> followUser(String userId);
  Future<void> unfollowUser(String userId);
  Future<List<PostModel>> getUserPosts(String userId, {String? cursor, int limit = 20});
  Future<List<AchievementModel>> getAchievements(String userId);
  Future<GamificationStatsModel> getGamificationStats(String userId);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _api;

  ProfileRemoteDataSourceImpl(this._api);

  @override
  Future<ProfileModel> getMyProfile() async {
    final response = await _api.get('/users/me');
    return ProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<ProfileModel> getUserProfile(String userId) async {
    final response = await _api.get('/users/$userId/profile');
    return ProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> getProfileStats(String userId) async {
    final response = await _api.get('/users/$userId/stats');
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<ProfileModel> updateProfile(Map<String, dynamic> fields) async {
    final response = await _api.patch('/users/me', data: fields);
    return ProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> followUser(String userId) async {
    await _api.post('/users/$userId/follow');
  }

  @override
  Future<void> unfollowUser(String userId) async {
    await _api.delete('/users/$userId/follow');
  }

  @override
  Future<List<PostModel>> getUserPosts(String userId, {String? cursor, int limit = 20}) async {
    final response = await _api.get(
      '/users/$userId/posts',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return (response.data as List? ?? [])
        .map((p) => PostModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AchievementModel>> getAchievements(String userId) async {
    final response = await _api.get('/gamification/achievements/$userId');
    final data = response.data as Map<String, dynamic>;
    return (data['achievements'] as List? ?? [])
        .map((a) => AchievementModel.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<GamificationStatsModel> getGamificationStats(String userId) async {
    final response = await _api.get('/gamification/stats/$userId');
    return GamificationStatsModel.fromJson(response.data as Map<String, dynamic>);
  }
}
