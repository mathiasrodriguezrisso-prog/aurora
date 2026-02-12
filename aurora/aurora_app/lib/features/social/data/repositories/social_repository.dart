import '../datasources/social_remote_datasource.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class SocialRepository {
  final SocialRemoteDataSource _remoteDataSource;

  SocialRepository(this._remoteDataSource);

  Future<List<PostModel>> getFeed({int page = 1}) async {
    try {
      return await _remoteDataSource.getFeed(page: page);
    } catch (e) {
      return [];
    }
  }

  Future<PostModel> createPost(String content, List<String> imageUrls) {
    return _remoteDataSource.createPost(content, imageUrls);
  }

  Future<bool> likePost(String postId) async {
    try {
      return await _remoteDataSource.toggleLike(postId);
    } catch (e) {
      return false;
    }
  }

  Future<List<CommentModel>> getComments(String postId) async {
    try {
      return await _remoteDataSource.getComments(postId);
    } catch (e) {
      return [];
    }
  }

  Future<CommentModel> createComment(String postId, String content) {
    return _remoteDataSource.createComment(postId, content);
  }
}
