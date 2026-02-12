/// UseCase: Obtener feed paginado con cursor.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/post_entity.dart';
import '../repositories/social_repository.dart';

class GetFeed {
  final SocialRepository _repository;

  GetFeed(this._repository);

  Future<Either<Failure, ({List<PostEntity> posts, String? nextCursor})>> call({
    String? cursor,
    int limit = 20,
    String? category,
  }) {
    return _repository.getFeed(cursor: cursor, limit: limit, category: category);
  }
}
