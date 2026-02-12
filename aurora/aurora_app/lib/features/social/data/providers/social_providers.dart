import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/social_remote_datasource.dart';
import '../repositories/social_repository.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

// 1. Data Source (no longer needs ApiClient)
final socialRemoteDataSourceProvider = Provider<SocialRemoteDataSource>((ref) {
  return SocialRemoteDataSource();
});

// 2. Repository
final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepository(ref.watch(socialRemoteDataSourceProvider));
});

// 3. Feed Provider (AsyncValue List of Posts)
final feedProvider = FutureProvider.autoDispose<List<PostModel>>((ref) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getFeed();
});

// 4. Comments Provider (Family to fetch by postId)
final postCommentsProvider = FutureProvider.family.autoDispose<List<CommentModel>, String>((ref, postId) async {
  final repo = ref.watch(socialRepositoryProvider);
  return repo.getComments(postId);
});
