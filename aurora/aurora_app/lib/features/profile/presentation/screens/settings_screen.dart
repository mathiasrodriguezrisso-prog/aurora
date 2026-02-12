import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aurora_app/core/config/app_theme.dart';
import 'package:aurora_app/shared/widgets/glass_container.dart';
import 'package:aurora_app/features/auth/presentation/providers/auth_providers.dart';
import '../../data/providers/profile_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final userEmail = Supabase.instance.client.auth.currentUser?.email ?? 'No email';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ACCOUNT SECTION
            const Text('ACCOUNT', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            GlassContainer(
              child: ListTile(
                leading: const Icon(Icons.email_outlined, color: AppTheme.primary),
                title: const Text('Email', style: TextStyle(color: Colors.white70, fontSize: 13)),
                subtitle: Text(userEmail, style: const TextStyle(color: Colors.white, fontSize: 15)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 24),

            // NOTIFICATIONS SECTION
            const Text('NOTIFICATIONS', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            GlassContainer(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Push Notifications', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Get alerts for tasks and updates', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: settings.pushEnabled,
                    activeColor: AppTheme.primary,
                    onChanged: notifier.togglePush,
                    contentPadding: EdgeInsets.zero,
                  ),
                  Divider(color: AppTheme.glassBorder, height: 1),
                  SwitchListTile(
                    title: const Text('Dark Mode', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Always on for Aurora', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: settings.darkMode,
                    activeColor: AppTheme.primary,
                    onChanged: notifier.toggleTheme,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ABOUT SECTION
            const Text('ABOUT', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            GlassContainer(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: AppTheme.primary),
                    title: const Text('Version', style: TextStyle(color: Colors.white)),
                    trailing: const Text('Aurora v1.0.0 MVP', style: TextStyle(color: AppTheme.primary, fontSize: 13)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  Divider(color: AppTheme.glassBorder, height: 1),
                  ListTile(
                    leading: const Icon(Icons.eco, color: AppTheme.primary),
                    title: const Text('Made with', style: TextStyle(color: Colors.white)),
                    trailing: const Text('🌱 Flutter + Supabase', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // LOGOUT SECTION
            GlassContainer(
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppTheme.error),
                title: const Text('Logout', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
                contentPadding: EdgeInsets.zero,
                onTap: () => _showLogoutDialog(context, ref),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await Supabase.instance.client.auth.signOut();
                ref.read(authProvider.notifier).signOut();
              } catch (_) {}
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Logout', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
