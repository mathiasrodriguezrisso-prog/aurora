/// 📁 lib/features/profile/domain/usecases/get_my_profile.dart

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetMyProfile {
  final ProfileRepository repository;

  GetMyProfile(this.repository);

  Future<Either<Failure, ProfileEntity>> call() async {
    return await repository.getMyProfile();
  }
}
