/// 📁 lib/features/profile/domain/usecases/update_profile.dart

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/profile_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateProfile {
  final ProfileRepository repository;

  UpdateProfile(this.repository);

  Future<Either<Failure, ProfileEntity>> call({
    String? displayName,
    String? bio,
    String? location,
    String? growStyle,
    String? experienceLevel,
    String? avatarUrl,
  }) async {
    return await repository.updateProfile(
      displayName: displayName,
      bio: bio,
      location: location,
      growStyle: growStyle,
      experienceLevel: experienceLevel,
      avatarUrl: avatarUrl,
    );
  }
}
