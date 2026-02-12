/// Proveedores de Riverpod para el módulo Social.
/// DI chain: DataSource → Repository → UseCases → Notifiers.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/social_remote_datasource.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/social_repository_impl.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/repositories/social_repository.dart';
import '../../domain/usecases/add_comment.dart';
import '../../domain/usecases/create_post.dart';
import '../../domain/usecases/get_comments.dart';
import '../../domain/usecases/get_feed.dart';
import '../../domain/usecases/get_trending.dart';
import '../../domain/usecases/toggle_like.dart';

// ─────────────────────────────────────────────────────
// Dependency Injection
// ─────────────────────────────────────────────────────

final socialDataSourceProvider = Provider<SocialRemoteDataSource>((ref) {
  final api = ref.watch(apiClientProvider);
  return SocialRemoteDataSource(api);
});

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepositoryImpl(ref.watch(socialDataSourceProvider));
});

// -- UseCases --

final getFeedUseCaseProvider = Provider<GetFeed>((ref) {
  return GetFeed(ref.watch(socialRepositoryProvider));
});

final createPostUseCaseProvider = Provider<CreatePost>((ref) {
  return CreatePost(ref.watch(socialRepositoryProvider));
});

final toggleLikeUseCaseProvider = Provider<ToggleLike>((ref) {
  return ToggleLike(ref.watch(socialRepositoryProvider));
});

final addCommentUseCaseProvider = Provider<AddComment>((ref) {
  return AddComment(ref.watch(socialRepositoryProvider));
});

final getCommentsUseCaseProvider = Provider<GetComments>((ref) {
  return GetComments(ref.watch(socialRepositoryProvider));
});

final getTrendingUseCaseProvider = Provider<GetTrending>((ref) {
  return GetTrending(ref.watch(socialRepositoryProvider));
});

// ─────────────────────────────────────────────────────
// Feed State
// ─────────────────────────────────────────────────────

class FeedState {
  final List<PostModel> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final String? nextCursor;
  final String? errorMessage;
  final String? activeCategory;

  const FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.nextCursor,
    this.errorMessage,
    this.activeCategory,
  });

  FeedState copyWith({
    List<PostModel>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    String? nextCursor,
    String? errorMessage,
    String? activeCategory,
    bool clearError = false,
    bool clearCursor = false,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeCategory: activeCategory ?? this.activeCategory,
    );
  }
}

// ─────────────────────────────────────────────────────
// Feed Notifier
// ─────────────────────────────────────────────────────

class FeedNotifier extends StateNotifier<FeedState> {
  final GetFeed _getFeed;
  final ToggleLike _toggleLike;
  final AddComment _addComment;
  final CreatePost _createPost;

  FeedNotifier({
    required GetFeed getFeed,
    required ToggleLike toggleLike,
    required AddComment addComment,
    required CreatePost createPost,
  })  : _getFeed = getFeed,
        _toggleLike = toggleLike,
        _addComment = addComment,
        _createPost = createPost,
        super(const FeedState());

  /// Carga inicial del feed.
  Future<void> loadFeed({String? category}) async {
    state = FeedState(isLoading: true, activeCategory: category);

    final result = await _getFeed(category: category);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (data) => state = state.copyWith(
        isLoading: false,
        posts: data.posts.map((e) => PostModel.fromEntity(e)).toList(),
        nextCursor: data.nextCursor,
        hasReachedEnd: data.nextCursor == null,
        clearError: true,
      ),
    );
  }

  /// Carga más posts (infinite scroll).
  Future<void> loadMore() async {
    if (state.isLoadingMore || state.hasReachedEnd) return;

    state = state.copyWith(isLoadingMore: true);

    final result = await _getFeed(
      cursor: state.nextCursor,
      category: state.activeCategory,
    );
    result.fold(
      (failure) => state = state.copyWith(
        isLoadingMore: false,
        errorMessage: failure.message,
      ),
      (data) {
        final newPosts =
            data.posts.map((e) => PostModel.fromEntity(e)).toList();
        state = state.copyWith(
          isLoadingMore: false,
          posts: [...state.posts, ...newPosts],
          nextCursor: data.nextCursor,
          hasReachedEnd: data.nextCursor == null,
          clearError: true,
        );
      },
    );
  }

  /// Refresh completo (pull-to-refresh).
  Future<void> refresh() async {
    await loadFeed(category: state.activeCategory);
  }

  /// Cambia categoría y recarga.
  Future<void> setCategory(String? category) async {
    if (category == state.activeCategory) return;
    await loadFeed(category: category);
  }

  /// Toggle like/unlike — optimistic update + revert on error.
  Future<void> toggleLike(String postId) async {
    final index = state.posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = state.posts[index];
    final wasLiked = post.isLiked;
    final updatedPosts = [...state.posts];

    // Optimistic update
    updatedPosts[index] = post.copyWith(
      isLiked: !wasLiked,
      likesCount: wasLiked ? post.likesCount - 1 : post.likesCount + 1,
    );
    state = state.copyWith(posts: updatedPosts);

    // API call
    final result =
        await _toggleLike(postId, isCurrentlyLiked: wasLiked);
    result.fold(
      (failure) {
        // Revert on error
        final revertPosts = [...state.posts];
        final currentIndex = revertPosts.indexWhere((p) => p.id == postId);
        if (currentIndex != -1) {
          revertPosts[currentIndex] = post; // restore original
          state = state.copyWith(posts: revertPosts);
        }
        debugPrint('Like toggle error: ${failure.message}');
      },
      (_) {
        // Success — no action needed, optimistic was correct
      },
    );
  }

  /// Agrega un comentario optimísticamente (incrementa count).
  Future<void> addComment(String postId, String text) async {
    final result = await _addComment(postId, text);
    result.fold(
      (failure) => debugPrint('Comment error: ${failure.message}'),
      (comment) {
        // Incrementar commentsCount del post
        final updatedPosts = state.posts.map((p) {
          if (p.id == postId) {
            return p.copyWith(commentsCount: p.commentsCount + 1);
          }
          return p;
        }).toList();
        state = state.copyWith(posts: updatedPosts);
      },
    );
  }

  /// Agrega un post nuevo al inicio del feed.
  void addPost(PostModel post) {
    state = state.copyWith(posts: [post, ...state.posts]);
  }

  /// Crea un post a través del usecase y lo agrega al feed.
  Future<PostEntity?> createPost({
    required String content,
    required String category,
    List<String> imageUrls = const [],
    String? growId,
  }) async {
    final result = await _createPost(
      content: content,
      category: category,
      imageUrls: imageUrls,
      growId: growId,
    );
    return result.fold(
      (failure) {
        debugPrint('Create post error: ${failure.message}');
        return null;
      },
      (post) {
        addPost(PostModel.fromEntity(post));
        return post;
      },
    );
  }
}

// ─────────────────────────────────────────────────────
// Feed Provider
// ─────────────────────────────────────────────────────

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(
    getFeed: ref.watch(getFeedUseCaseProvider),
    toggleLike: ref.watch(toggleLikeUseCaseProvider),
    addComment: ref.watch(addCommentUseCaseProvider),
    createPost: ref.watch(createPostUseCaseProvider),
  );
});

// ─────────────────────────────────────────────────────
// Comments Provider (per-post, cursor-based)
// ─────────────────────────────────────────────────────

class CommentsState {
  final List<CommentEntity> comments;
  final bool isLoading;
  final String? nextCursor;
  final bool hasReachedEnd;
  final String? errorMessage;

  const CommentsState({
    this.comments = const [],
    this.isLoading = false,
    this.nextCursor,
    this.hasReachedEnd = false,
    this.errorMessage,
  });
}

final postCommentsProvider = FutureProvider.autoDispose
    .family<List<CommentEntity>, String>((ref, postId) async {
  final getComments = ref.watch(getCommentsUseCaseProvider);
  final result = await getComments(postId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => data.comments,
  );
});

// ─────────────────────────────────────────────────────
// Trending Provider
// ─────────────────────────────────────────────────────

final trendingProvider =
    FutureProvider.autoDispose<List<PostEntity>>((ref) async {
  final getTrending = ref.watch(getTrendingUseCaseProvider);
  final result = await getTrending();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (posts) => posts,
  );
});
