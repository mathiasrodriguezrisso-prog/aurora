/// DataSource remoto para el módulo Social.
/// Usa ApiClient (Dio) con JWT automático.
/// Paginación por cursor, no por página.
library;

import '../../../../core/network/api_client.dart';

class SocialRemoteDataSource {
  final ApiClient _api;

  SocialRemoteDataSource(this._api);

  // ─────────────────────────────────────────────────────
  // Feed
  // ─────────────────────────────────────────────────────

  /// GET /social/feed?cursor=X&limit=Y&category=Z
  /// Retorna Map con 'posts' y 'next_cursor'.
  Future<Map<String, dynamic>> getFeed({
    String? cursor,
    int limit = 20,
    String? category,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
      if (category != null) 'category': category,
    };

    final response = await _api.get(
      '/social/feed',
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────────────
  // Post CRUD
  // ─────────────────────────────────────────────────────

  /// GET /social/posts/:id
  Future<Map<String, dynamic>> getPost(String postId) async {
    final response = await _api.get('/social/posts/$postId');
    return response.data as Map<String, dynamic>;
  }

  /// POST /social/posts
  Future<Map<String, dynamic>> createPost(Map<String, dynamic> data) async {
    final response = await _api.post('/social/posts', data: data);
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /social/posts/:id
  Future<void> deletePost(String postId) async {
    await _api.delete('/social/posts/$postId');
  }

  // ─────────────────────────────────────────────────────
  // Likes
  // ─────────────────────────────────────────────────────

  /// POST /social/posts/:id/like
  Future<void> likePost(String postId) async {
    await _api.post('/social/posts/$postId/like');
  }

  /// DELETE /social/posts/:id/like
  Future<void> unlikePost(String postId) async {
    await _api.delete('/social/posts/$postId/like');
  }

  // ─────────────────────────────────────────────────────
  // Comments
  // ─────────────────────────────────────────────────────

  /// GET /social/posts/:id/comments?cursor=X&limit=Y
  Future<Map<String, dynamic>> getComments(
    String postId, {
    String? cursor,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    };
    final response = await _api.get(
      '/social/posts/$postId/comments',
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /social/posts/:id/comments
  Future<Map<String, dynamic>> addComment(
      String postId, Map<String, dynamic> data) async {
    final response = await _api.post(
      '/social/posts/$postId/comments',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────────────
  // Report
  // ─────────────────────────────────────────────────────

  /// POST /social/report
  Future<void> reportContent(Map<String, dynamic> data) async {
    await _api.post('/social/report', data: data);
  }

  // ─────────────────────────────────────────────────────
  // Trending
  // ─────────────────────────────────────────────────────

  /// GET /social/trending
  Future<List<dynamic>> getTrending() async {
    final response = await _api.get('/social/trending');
    return response.data as List<dynamic>;
  }
}
