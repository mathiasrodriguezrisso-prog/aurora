/// UseCase: Obtener comentarios de un post con cursor.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/comment_entity.dart';
import '../repositories/social_repository.dart';

class GetComments {
  final SocialRepository _repository;

  GetComments(this._repository);

  Future<Either<Failure, ({List<CommentEntity> comments, String? nextCursor})>>
      call(String postId, {String? cursor, int limit = 20}) {
    return _repository.getComments(postId, cursor: cursor, limit: limit);
  }
}
