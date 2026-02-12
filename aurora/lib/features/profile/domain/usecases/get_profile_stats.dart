/// 📁 lib/features/profile/domain/usecases/get_profile_stats.dart

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/profile_stats_entity.dart';
import '../repositories/profile_repository.dart';

class GetProfileStats {
  final ProfileRepository repository;

  GetProfileStats(this.repository);

  Future<Either<Failure, ProfileStatsEntity>> call(String userId) async {
    return await repository.getProfileStats(userId);
  }
}
