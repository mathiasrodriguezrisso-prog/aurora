/// UseCase: Crear un nuevo post.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/post_entity.dart';
import '../repositories/social_repository.dart';

class CreatePost {
  final SocialRepository _repository;

  CreatePost(this._repository);

  Future<Either<Failure, PostEntity>> call({
    required String content,
    required String category,
    List<String> imageUrls = const [],
    String? growId,
  }) {
    return _repository.createPost(
      content: content,
      category: category,
      imageUrls: imageUrls,
      growId: growId,
    );
  }
}
