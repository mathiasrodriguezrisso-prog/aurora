/// 📁 lib/features/profile/domain/usecases/get_user_profile.dart

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetUserProfile {
  final ProfileRepository repository;

  GetUserProfile(this.repository);

  Future<Either<Failure, ProfileEntity>> call(String userId) async {
    return await repository.getUserProfile(userId);
  }
}
