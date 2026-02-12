/// 📁 lib/features/social/presentation/screens/public_profile_screen.dart
/// Public profile view for other users — shows stats, follow/unfollow button,
/// and recent posts.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/post_model.dart';
import '../../presentation/widgets/post_card.dart';
import '../../../profile/domain/entities/profile_entity.dart';
import '../../../profile/domain/entities/profile_stats_entity.dart';
import '../../../profile/data/providers/profile_providers.dart';

class UserProfileScreen extends ConsumerWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(publicProfileProvider(userId).select((s) => s.profile));
    final isLoading = ref.watch(publicProfileProvider(userId).select((s) => s.isLoading));
    final stats = ref.watch(publicProfileProvider(userId).select((s) => s.stats));
    final posts = ref.watch(publicProfileProvider(userId).select((s) => s.posts));
 
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: isLoading && profile == null
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : profile == null
                ? _buildNotFound(context)
                : CustomScrollView(
                    slivers: [
                      _buildSliverAppBar(context, profile),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Column(
                            children: [
                              // Follow button
                              _buildFollowButton(ref, profile),
                              const SizedBox(height: 24),
                              // Stats
                              _buildStats(stats),
                              const SizedBox(height: 24),
                              // Divider
                              const Divider(color: AppTheme.glassBorder, height: 1),
                              const SizedBox(height: 24),
                              // Posts header
                              _buildPostsHeader(),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                      // Posts List
                      _buildPostsList(posts, isLoading),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Perfil no encontrado', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => context.pop(), child: const Text('Volver')),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ProfileEntity profile) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.primary.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                _buildAvatar(profile),
                const SizedBox(height: 12),
                Text(
                  profile.displayName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '@${profile.username}',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      profile.bio!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ProfileEntity profile) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
      ),
      child: CircleAvatar(
        radius: 48,
        backgroundColor: AppTheme.glassBackground,
        backgroundImage: profile.avatarUrl != null ? CachedNetworkImageProvider(profile.avatarUrl!) : null,
        child: profile.avatarUrl == null
            ? Text(
                profile.displayName[0].toUpperCase(),
                style: const TextStyle(fontSize: 32, color: AppTheme.primary),
              )
            : null,
      ),
    );
  }

  Widget _buildFollowButton(WidgetRef ref, ProfileEntity profile) {
    return SizedBox(
      width: 200,
      height: 44,
      child: ElevatedButton(
        onPressed: () => ref.read(publicProfileProvider(userId).notifier).toggleFollow(),
        style: ElevatedButton.styleFrom(
          backgroundColor: profile.isFollowing ? Colors.transparent : AppTheme.primary,
          foregroundColor: profile.isFollowing ? AppTheme.textPrimary : Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: profile.isFollowing ? const BorderSide(color: AppTheme.glassBorder) : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: Text(
          profile.isFollowing ? 'Siguiendo' : 'Seguir Grower',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildPostsHeader() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Posts Recientes',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPostsList(List<PostEntity> posts, bool isLoading) {
    if (isLoading && posts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        ),
      );
    }
    if (posts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Sin publicaciones aún', style: TextStyle(color: AppTheme.textTertiary))),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: PostCard(post: posts[index], onLike: () {}),
        ),
        childCount: posts.length,
      ),
    );
  }

  Widget _buildStats(ProfileStatsEntity? stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.glassBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statItem('${stats?.followers ?? 0}', 'Seguidores'),
                _divider(),
                _statItem('${stats?.following ?? 0}', 'Siguiendo'),
                _divider(),
                _statItem('${stats?.totalPosts ?? 0}', 'Posts'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textTertiary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 30, color: AppTheme.glassBorder);
  }
}
