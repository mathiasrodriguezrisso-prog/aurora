/// Interfaz abstracta del repositorio Social.
/// Todas las operaciones retornan `Either<Failure, T>`.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/comment_entity.dart';
import '../entities/post_entity.dart';

/// Contrato para fetch, create, like/unlike, comentar, y reportar.
abstract class SocialRepository {
  /// Obtiene el feed paginado con cursor.
  Future<Either<Failure, ({List<PostEntity> posts, String? nextCursor})>> getFeed({
    String? cursor,
    int limit = 20,
    String? category,
  });

  /// Obtiene un post individual por ID.
  Future<Either<Failure, PostEntity>> getPost(String postId);

  /// Crea un nuevo post.
  Future<Either<Failure, PostEntity>> createPost({
    required String content,
    required String category,
    List<String> imageUrls = const [],
    String? growId,
  });

  /// Elimina un post del usuario actual.
  Future<Either<Failure, void>> deletePost(String postId);

  /// Da like a un post.
  Future<Either<Failure, void>> likePost(String postId);

  /// Quita like de un post.
  Future<Either<Failure, void>> unlikePost(String postId);

  /// Obtiene comentarios de un post con cursor.
  Future<Either<Failure, ({List<CommentEntity> comments, String? nextCursor})>>
      getComments(String postId, {String? cursor, int limit = 20});

  /// Agrega un comentario a un post.
  Future<Either<Failure, CommentEntity>> addComment(
      String postId, String content);

  /// Reporta un post o comentario.
  Future<Either<Failure, void>> reportContent({
    required String reason,
    String? postId,
    String? commentId,
  });

  /// Obtiene posts trending.
  Future<Either<Failure, List<PostEntity>>> getTrending();
}
