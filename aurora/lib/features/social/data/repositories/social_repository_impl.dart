/// Implementación concreta de SocialRepository.
/// Mapea excepciones a Failures con Either<Failure, T>.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/repositories/social_repository.dart';
import '../datasources/social_remote_datasource.dart';
import '../models/post_model.dart';

class SocialRepositoryImpl implements SocialRepository {
  final SocialRemoteDataSource _dataSource;

  SocialRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, ({List<PostEntity> posts, String? nextCursor})>>
      getFeed({String? cursor, int limit = 20, String? category}) async {
    try {
      final data = await _dataSource.getFeed(
        cursor: cursor,
        limit: limit,
        category: category,
      );

      final rawPosts = data['posts'] as List<dynamic>? ?? [];
      final posts = rawPosts
          .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final nextCursor = data['next_cursor'] as String?;

      return Right((posts: posts, nextCursor: nextCursor));
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, code: '${e.statusCode}'));
    } catch (e) {
      return Left(ServerFailure('Error al cargar feed: $e'));
    }
  }

  @override
  Future<Either<Failure, PostEntity>> getPost(String postId) async {
    try {
      final data = await _dataSource.getPost(postId);
      return Right(PostModel.fromJson(data));
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, code: '${e.statusCode}'));
    } catch (e) {
      return Left(ServerFailure('Error al cargar post: $e'));
    }
  }

  @override
  Future<Either<Failure, PostEntity>> createPost({
    required String content,
    required String category,
    List<String> imageUrls = const [],
    String? growId,
  }) async {
    try {
      final data = await _dataSource.createPost({
        'content': content,
        'category': category,
        'image_urls': imageUrls,
        if (growId != null) 'grow_id': growId,
      });
      return Right(PostModel.fromJson(data));
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, code: '${e.statusCode}'));
    } catch (e) {
      return Left(ServerFailure('Error al crear post: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePost(String postId) async {
    try {
      await _dataSource.deletePost(postId);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, code: '${e.statusCode}'));
    } catch (e) {
      return Left(ServerFailure('Error al eliminar post: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> likePost(String postId) async {
    try {
      await _dataSource.likePost(postId);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, code: '${e.statusCode}'));
    } catch (e) {
      return Left(ServerFailure('Error al dar like: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> unlikePost(String postId) async {
    try {
      await _dataSource.unlikePost(postId);
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, code: '${e.statusCode}'));
    } catch (e) {
      return Left(ServerFailure('Error al quitar like: $e'));
    }
  }

  @override
  Future<Either<Failure, ({List<CommentEntity> comments, String? nextCursor})>>
      getComments(String postId, {String? cursor, int limit = 20}) async {
    try {
      final data = await _dataSource.getComments(
        postId,
        cursor: cursor,
        limit: limit,
      );

      final rawComments = data['comments'] as List<dynamic>? ?? [];
      final comments = rawComments
          .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final nextCursor = data['next_cursor'] as String?;

      return Right((comments: comments, nextCursor: nextCursor));
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, code: '${e.statusCode}'));
    } catch (e) {
      return Left(ServerFailure('Error al cargar comentarios: $e'));
    }
  }

  @override
  Future<Either<Failure, CommentEntity>> addComment(
      String postId, String content) async {
    try {
      final data = await _dataSource.addComment(postId, {'content': content});
      return Right(CommentModel.fromJson(data));
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, code: '${e.statusCode}'));
    } catch (e) {
      return Left(ServerFailure('Error al agregar comentario: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> reportContent({
    required String reason,
    String? postId,
    String? commentId,
  }) async {
    try {
      await _dataSource.reportContent({
        'reason': reason,
        if (postId != null) 'post_id': postId,
        if (commentId != null) 'comment_id': commentId,
      });
      return const Right(null);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, code: '${e.statusCode}'));
    } catch (e) {
      return Left(ServerFailure('Error al reportar: $e'));
    }
  }

  @override
  Future<Either<Failure, List<PostEntity>>> getTrending() async {
    try {
      final data = await _dataSource.getTrending();
      final posts = data
          .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(posts);
    } on ApiException catch (e) {
      return Left(ServerFailure(e.message, code: '${e.statusCode}'));
    } catch (e) {
      return Left(ServerFailure('Error al cargar trending: $e'));
    }
  }
}
