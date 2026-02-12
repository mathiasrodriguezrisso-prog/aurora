import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aurora_app/core/config/app_theme.dart';
import 'package:aurora_app/shared/widgets/aurora_button.dart';
import 'package:aurora_app/shared/widgets/glass_container.dart';
import 'package:aurora_app/features/social/data/providers/social_providers.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _strainController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  bool get _canPost => _contentController.text.trim().isNotEmpty || _selectedImage != null;

  @override
  void dispose() {
    _contentController.dispose();
    _strainController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
                title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppTheme.primary),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadImage(File imageFile) async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '$userId/$timestamp.jpg';
    final bytes = await imageFile.readAsBytes();

    await client.storage.from('post-images').uploadBinary(
      filePath,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );

    final publicUrl = client.storage.from('post-images').getPublicUrl(filePath);
    return publicUrl;
  }

  Future<void> _submit() async {
    if (!_canPost) return;

    setState(() => _isLoading = true);

    try {
      List<String> imageUrls = [];

      // Upload image if selected
      if (_selectedImage != null) {
        final url = await _uploadImage(_selectedImage!);
        if (url != null) imageUrls.add(url);
      }

      // Create the post
      final content = _contentController.text.trim();
      final strain = _strainController.text.trim();

      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final postData = <String, dynamic>{
        'user_id': userId,
        'content': content.isNotEmpty ? content : null,
        'image_urls': imageUrls,
        'created_at': DateTime.now().toIso8601String(),
      };
      if (strain.isNotEmpty) {
        postData['strain_tag'] = strain;
      }

      await client.from('posts').insert(postData);

      if (mounted) {
        ref.invalidate(feedProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('New Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _canPost && !_isLoading ? _submit : null,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                    )
                  : Text(
                      'Post',
                      style: TextStyle(
                        color: _canPost ? AppTheme.primary : Colors.white24,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content Field
            GlassContainer(
              child: TextField(
                controller: _contentController,
                maxLines: 6,
                minLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: "What's growing on? 🌱",
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),

            // Image Preview or Add Photo Button
            if (_selectedImage != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: GlassContainer(
                  child: SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppTheme.primary.withValues(alpha: 0.7)),
                        const SizedBox(height: 8),
                        const Text('Add Photo', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Strain Tag
            GlassContainer(
              child: TextField(
                controller: _strainController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Strain tag (optional)',
                  hintStyle: TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.local_florist, color: AppTheme.primary, size: 20),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Post Button (full width, alternative to AppBar button)
            AuroraButton(
              text: 'Share with Community ✨',
              isLoading: _isLoading,
              onPressed: _canPost ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
