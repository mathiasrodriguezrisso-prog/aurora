/// 📁 lib/features/social/presentation/screens/feed_screen.dart
/// Main social feed screen with shimmer loading, cursor pagination,
/// category filters, and pull-to-refresh.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_theme.dart';
import '../../data/providers/social_providers.dart';
import '../widgets/post_card.dart';
import '../widgets/post_shimmer.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();

  static const _categories = [
    null,
    'showcase',
    'question',
    'tutorial',
    'diary',
  ];
  static const _categoryLabels = [
    '🔥 All',
    '🌟 Showcase',
    '❓ Questions',
    '📘 Tutorials',
    '📖 Diaries',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Carga inicial del feed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedProvider.notifier).loadFeed();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: AppTheme.surface,
          onRefresh: () => ref.read(feedProvider.notifier).refresh(),
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                  'The Pulse 🌿',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppTheme.primary, size: 28),
                    onPressed: () => context.push('/feed/create'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Category filter chips
              SliverToBoxAdapter(child: _buildCategoryChips(state)),

              // Content
              if (state.isLoading)
                const FeedShimmerList(count: 3)
              else if (state.errorMessage != null && state.posts.isEmpty)
                SliverFillRemaining(child: _buildError(state.errorMessage!))
              else if (state.posts.isEmpty)
                SliverFillRemaining(child: _buildEmpty())
              else ...[
                // Posts list
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == state.posts.length) {
                        // Loading more indicator
                        return state.isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const SizedBox(height: 80);
                      }

                      final post = state.posts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: PostCard(
                          post: post,
                          onLike: () => ref
                              .read(feedProvider.notifier)
                              .toggleLike(post.id),
                        ),
                      );
                    },
                    childCount: state.posts.length + 1,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(FeedState state) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final label = _categoryLabels[index];
          final isActive = state.activeCategory == category;

          return GestureDetector(
            onTap: () => ref.read(feedProvider.notifier).setCategory(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primary.withValues(alpha: 0.2)
                    : AppTheme.glassBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive ? AppTheme.primary : AppTheme.glassBorder,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rss_feed_outlined,
              color: AppTheme.textTertiary, size: 56),
          const SizedBox(height: 12),
          const Text(
            'No posts yet',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Be the first to share your grow!',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push('/feed/create'),
            icon: const Icon(Icons.add),
            label: const Text('Create Post'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_outlined,
                color: AppTheme.error, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(feedProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
