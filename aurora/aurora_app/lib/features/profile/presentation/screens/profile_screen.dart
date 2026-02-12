import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora_app/core/config/app_theme.dart';
import 'package:aurora_app/shared/widgets/glass_container.dart';
import 'package:aurora_app/shared/widgets/shimmer_loading.dart';
import 'package:aurora_app/features/auth/presentation/providers/auth_providers.dart';
import '../../data/providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
            child: Column(
              children: [
                // Avatar & Info
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primary.withOpacity(0.2),
                  backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                  child: profile.avatarUrl == null ? const Icon(Icons.person, size: 50, color: AppTheme.primary) : null,
                ),
                const SizedBox(height: 16),
                Text(
                  profile.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Level ${profile.level} Grower',
                  style: const TextStyle(color: AppTheme.primary, fontSize: 16),
                ),
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    profile.bio!,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),

                // Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat('XP', '${profile.xp}'),
                    _buildStat('Karma', '${profile.karma}'),
                    _buildStat('Level', '${profile.level}'),
                  ],
                ),
                const SizedBox(height: 32),

                // Menu
                GlassContainer(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit, color: Colors.white),
                        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                        onTap: () => context.push('/edit-profile'),
                      ),
                      Divider(color: AppTheme.glassBorder),
                      ListTile(
                        leading: const Icon(Icons.share, color: Colors.white),
                        title: const Text('Public Profile', style: TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                        onTap: () => context.push('/public-profile'),
                      ),
                      Divider(color: AppTheme.glassBorder),
                      ListTile(
                        leading: const Icon(Icons.logout, color: AppTheme.error),
                        title: const Text('Logout', style: TextStyle(color: AppTheme.error)),
                        onTap: () async {
                          try {
                            await Supabase.instance.client.auth.signOut();
                            ref.read(authProvider.notifier).signOut();
                          } catch (_) {}
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShimmerLoading(height: 100, width: 100, borderRadius: 50),
              SizedBox(height: 16),
              ShimmerLoading(height: 24, width: 150, borderRadius: 8),
              SizedBox(height: 8),
              ShimmerLoading(height: 16, width: 100, borderRadius: 8),
            ],
          ),
        ),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.white24),
              const SizedBox(height: 16),
              Text('Error: $e', style: const TextStyle(color: AppTheme.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  foregroundColor: AppTheme.primary,
                ),
                onPressed: () => ref.refresh(userProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
