/// 📁 lib/features/profile/data/repositories/profile_repository_impl.dart

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/profile_stats_entity.dart';
import '../../domain/entities/gamification_stats_entity.dart';
import '../../domain/entities/achievement_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';
import '../../../social/domain/entities/post_entity.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, ProfileEntity>> getMyProfile() async {
    try {
      final profile = await remoteDataSource.getMyProfile();
      return Right(profile);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> getUserProfile(String userId) async {
    try {
      final profile = await remoteDataSource.getUserProfile(userId);
      return Right(profile);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GamificationStatsEntity>> getProfileStats(String userId) async {
    try {
      final stats = await remoteDataSource.getGamificationStats(userId);
      return Right(stats);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AchievementEntity>>> getAchievements(String userId) async {
    try {
      final achievements = await remoteDataSource.getAchievements(userId);
      return Right(achievements);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? displayName,
    String? bio,
    String? location,
    String? growStyle,
    String? experienceLevel,
    String? avatarUrl,
  }) async {
    try {
      final fields = <String, dynamic>{};
      if (displayName != null) fields['display_name'] = displayName;
      if (bio != null) fields['bio'] = bio;
      if (location != null) fields['location'] = location;
      if (growStyle != null) fields['grow_style'] = growStyle;
      if (experienceLevel != null) fields['experience_level'] = experienceLevel;
      if (avatarUrl != null) fields['avatar_url'] = avatarUrl;

      final profile = await remoteDataSource.updateProfile(fields);
      return Right(profile);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> followUser(String userId) async {
    try {
      await remoteDataSource.followUser(userId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> unfollowUser(String userId) async {
    try {
      await remoteDataSource.unfollowUser(userId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  @override
  Future<Either<Failure, List<PostEntity>>> getUserPosts(String userId, {String? cursor, int limit = 20}) async {
    try {
      final posts = await remoteDataSource.getUserPosts(userId, cursor: cursor, limit: limit);
      return Right(posts);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
