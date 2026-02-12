/// 📁 lib/features/profile/domain/repositories/profile_repository.dart

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/profile_entity.dart';
import '../entities/profile_stats_entity.dart';
import '../entities/gamification_stats_entity.dart';
import '../entities/achievement_entity.dart';
import '../../../social/domain/entities/post_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileEntity>> getMyProfile();
  
  Future<Either<Failure, ProfileEntity>> getUserProfile(String userId);
  
  Future<Either<Failure, GamificationStatsEntity>> getProfileStats(String userId);

  Future<Either<Failure, List<AchievementEntity>>> getAchievements(String userId);
  
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? displayName,
    String? bio,
    String? location,
    String? growStyle,
    String? experienceLevel,
    String? avatarUrl,
  });
  
  Future<Either<Failure, Unit>> followUser(String userId);
  
  Future<Either<Failure, Unit>> unfollowUser(String userId);
  Future<Either<Failure, List<PostEntity>>> getUserPosts(String userId, {String? cursor, int limit = 20});
}
