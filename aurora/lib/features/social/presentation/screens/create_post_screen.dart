/// 📁 lib/features/social/presentation/screens/create_post_screen.dart
/// Create a new social post with text, category, grow link, and images.
library;

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../shared/services/image_upload_service.dart';
import '../../data/providers/social_providers.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  String _selectedCategory = 'showcase';
  bool _isPosting = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  static const _categories = ['showcase', 'question', 'tutorial', 'diary'];
  static const _categoryEmojis = ['🌟', '❓', '📘', '📖'];
  static const _categoryLabels = ['Showcase', 'Question', 'Tutorial', 'Diary'];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(child: _buildForm()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
            onPressed: () => context.pop(),
          ),
          _isPosting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                    strokeWidth: 2,
                  ),
                )
              : ElevatedButton(
                  onPressed: _contentController.text.trim().isEmpty
                      ? null
                      : _submitPost,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Post'),
                ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content field
          TextField(
            controller: _contentController,
            maxLines: 8,
            maxLength: 2000,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: 'Share your grow journey...',
              hintStyle: TextStyle(
                color: AppTheme.textTertiary.withValues(alpha: 0.6),
              ),
              border: InputBorder.none,
              counterStyle: const TextStyle(color: AppTheme.textTertiary),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Category selector
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CATEGORY',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_categories.length, (i) {
                        final isActive =
                            _selectedCategory == _categories[i];
                        return GestureDetector(
                          onTap: () => setState(
                              () => _selectedCategory = _categories[i]),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppTheme.primary.withValues(alpha: 0.2)
                                  : AppTheme.glassBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive
                                    ? AppTheme.primary
                                    : AppTheme.glassBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_categoryEmojis[i],
                                    style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  _categoryLabels[i],
                                  style: TextStyle(
                                    color: isActive
                                        ? AppTheme.primary
                                        : AppTheme.textSecondary,
                                    fontSize: 13,
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Photo grid + add button
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Selected images
                for (var i = 0; i < _selectedImages.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_selectedImages[i].path),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _selectedImages.removeAt(i)),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.close,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Add photo button (if < 5)
                if (_selectedImages.length < 5)
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.glassBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined,
                              color: AppTheme.textTertiary, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedImages.length}/5',
                            style: const TextStyle(
                                color: AppTheme.textTertiary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Upload progress
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: AppTheme.glassBackground,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final remaining = 5 - _selectedImages.length;
      final picked = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(picked.take(remaining));
        });
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final uploadService = ref.read(imageUploadServiceProvider);
      final files = _selectedImages.map((x) => File(x.path)).toList();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final urls = await uploadService.uploadMultiple(
        imageFiles: files,
        bucket: 'post-images',
        basePath: 'posts/$timestamp',
      );

      setState(() => _uploadProgress = 1.0);
      return urls;
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _submitPost() async {
    if (_contentController.text.trim().isEmpty) return;
    setState(() => _isPosting = true);
    HapticFeedback.lightImpact();

    try {
      // Upload images first
      final imageUrls = await _uploadImages();

      // Create post via provider
      final post = await ref.read(feedProvider.notifier).createPost(
            content: _contentController.text.trim(),
            category: _selectedCategory,
            imageUrls: imageUrls,
          );

      if (post != null && mounted) {
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create post'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }
}
