/// UseCase: Obtener posts trending.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/post_entity.dart';
import '../repositories/social_repository.dart';

class GetTrending {
  final SocialRepository _repository;

  GetTrending(this._repository);

  Future<Either<Failure, List<PostEntity>>> call() {
    return _repository.getTrending();
  }
}
