/// UseCase: Agregar un comentario a un post.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/comment_entity.dart';
import '../repositories/social_repository.dart';

class AddComment {
  final SocialRepository _repository;

  AddComment(this._repository);

  Future<Either<Failure, CommentEntity>> call(String postId, String content) {
    return _repository.addComment(postId, content);
  }
}
