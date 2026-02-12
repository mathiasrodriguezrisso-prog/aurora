/// UseCase: Obtener un post individual.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/post_entity.dart';
import '../repositories/social_repository.dart';

class GetPost {
  final SocialRepository _repository;

  GetPost(this._repository);

  Future<Either<Failure, PostEntity>> call(String postId) {
    return _repository.getPost(postId);
  }
}
