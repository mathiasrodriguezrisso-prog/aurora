/// UseCase: Reportar un post o comentario.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/social_repository.dart';

class ReportContent {
  final SocialRepository _repository;

  ReportContent(this._repository);

  Future<Either<Failure, void>> call({
    required String reason,
    String? postId,
    String? commentId,
  }) {
    return _repository.reportContent(
      reason: reason,
      postId: postId,
      commentId: commentId,
    );
  }
}
