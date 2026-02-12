import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aurora_app/core/config/app_theme.dart';
import 'package:aurora_app/shared/widgets/aurora_text_field.dart';
import 'package:aurora_app/shared/widgets/aurora_button.dart';
import '../../data/providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initControllers(UserProfile profile) {
    if (!_initialized) {
      _nameController.text = profile.displayName;
      _bioController.text = profile.bio ?? '';
      _initialized = true;
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updateFn = ref.read(updateProfileProvider);
      await updateFn({
        'display_name': name,
        'bio': _bioController.text.trim(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated! ✨'), backgroundColor: AppTheme.primary),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: profileAsync.when(
        data: (profile) {
          _initControllers(profile);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primary.withOpacity(0.2),
                  backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                  child: profile.avatarUrl == null
                      ? const Icon(Icons.person, size: 40, color: AppTheme.primary)
                      : null,
                ),
                const SizedBox(height: 24),

                AuroraTextField(hint: 'Display Name', controller: _nameController),
                const SizedBox(height: 16),
                AuroraTextField(hint: 'Bio (optional)', controller: _bioController),
                const SizedBox(height: 32),

                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : AuroraButton(
                        text: 'Save Changes',
                        onPressed: _save,
                      ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, s) => Center(
          child: Text('Error loading profile: $e', style: const TextStyle(color: AppTheme.error)),
        ),
      ),
    );
  }
}
