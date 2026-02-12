/// UseCase: Dar like / quitar like a un post.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/social_repository.dart';

class ToggleLike {
  final SocialRepository _repository;

  ToggleLike(this._repository);

  /// Si [isCurrentlyLiked] es true, quita el like; si es false, lo da.
  Future<Either<Failure, void>> call(String postId, {required bool isCurrentlyLiked}) {
    if (isCurrentlyLiked) {
      return _repository.unlikePost(postId);
    } else {
      return _repository.likePost(postId);
    }
  }
}
