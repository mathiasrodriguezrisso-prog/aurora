import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class SocialRemoteDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<PostModel>> getFeed({int page = 1, int limit = 20}) async {
    try {
      final response = await _client
          .from('posts')
          .select('''
            *,
            profiles!posts_user_id_fkey (id, display_name, avatar_url)
          ''')
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      final List data = response as List;
      return data.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<PostModel> createPost(String content, List<String> imageUrls) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client
        .from('posts')
        .insert({
          'user_id': userId,
          'content': content,
          'image_urls': imageUrls,
        })
        .select('''
          *,
          profiles!posts_user_id_fkey (id, display_name, avatar_url)
        ''')
        .single();

    return PostModel.fromJson(response);
  }

  Future<bool> toggleLike(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    try {
      final existing = await _client
          .from('likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        await _client
            .from('likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
        return false;
      } else {
        await _client.from('likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  Future<List<CommentModel>> getComments(String postId) async {
    try {
      final response = await _client
          .from('comments')
          .select('''
            *,
            profiles!comments_user_id_fkey (id, display_name, avatar_url)
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      final List data = response as List;
      return data.map((json) => CommentModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<CommentModel> createComment(String postId, String content) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client
        .from('comments')
        .insert({
          'post_id': postId,
          'user_id': userId,
          'content': content,
        })
        .select('''
          *,
          profiles!comments_user_id_fkey (id, display_name, avatar_url)
        ''')
        .single();

    return CommentModel.fromJson(response);
  }
}
