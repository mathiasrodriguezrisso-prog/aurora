/// 📁 lib/features/grow/presentation/widgets/grow_gallery.dart
/// Gallery tab showing grow photos organized by day with
/// camera capture, image_picker integration, and Supabase storage upload.
library;

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/empty_state.dart';

class GrowGallery extends ConsumerStatefulWidget {
  final String growId;
  final int currentDay;

  const GrowGallery({
    super.key,
    required this.growId,
    required this.currentDay,
  });

  @override
  ConsumerState<GrowGallery> createState() => _GrowGalleryState();
}

class _GrowGalleryState extends ConsumerState<GrowGallery> {
  List<Map<String, dynamic>> _photos = [];
  bool _loading = true;
  bool _uploading = false;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final response = await Supabase.instance.client
          .from('grow_photos')
          .select()
          .eq('grow_id', widget.growId)
          .order('day_number', ascending: false);

      setState(() {
        _photos = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppTheme.primary,
          strokeWidth: 2,
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // Header with photo count
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_photos.length} Photos',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Add photo button
                GestureDetector(
                  onTap: _uploading ? null : _addPhoto,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _uploading
                          ? AppTheme.textTertiary.withValues(alpha: 0.1)
                          : AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _uploading
                            ? AppTheme.textTertiary.withValues(alpha: 0.2)
                            : AppTheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: _uploading
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Uploading…',
                                style: TextStyle(
                                  color: AppTheme.textTertiary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  size: 16, color: AppTheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Add Photo',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Photo grid or empty state
        if (_photos.isEmpty)
          SliverFillRemaining(
            child: _buildEmptyState(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final photo = _photos[index];
                  return _PhotoTile(
                    imageUrl: photo['image_url'] as String? ?? '',
                    day: photo['day_number'] as int? ?? 0,
                    onTap: () => _showPhotoDetail(photo),
                    onLongPress: () => _confirmDelete(photo),
                  );
                },
                childCount: _photos.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.photo_library_outlined,
      title: 'No photos yet',
      subtitle: 'Document your grow journey by adding photos of your plants.',
      actionLabel: 'Take First Photo',
      onAction: _addPhoto,
    );
  }

  /// Open camera or gallery picker, upload to Supabase, and save metadata.
  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: AppTheme.primary),
              ),
              title: const Text('Camera', style: TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text('Take a new photo', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.photo_library, color: AppTheme.secondary),
              ),
              title: const Text('Gallery', style: TextStyle(color: AppTheme.textPrimary)),
              subtitle: Text('Choose existing photo', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _uploading = true);
      HapticFeedback.lightImpact();

      final sb = Supabase.instance.client;
      final userId = sb.auth.currentUser?.id ?? 'anon';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = picked.path.split('.').last;
      final storagePath = 'grows/${widget.growId}/${userId}_$timestamp.$ext';
      final fileBytes = await picked.readAsBytes();

      // Upload to Supabase Storage
      await sb.storage
          .from('grow-photos')
          .uploadBinary(storagePath, fileBytes, fileOptions: FileOptions(contentType: 'image/$ext'));

      final publicUrl = sb.storage.from('grow-photos').getPublicUrl(storagePath);

      // Save metadata to DB
      await sb.from('grow_photos').insert({
        'grow_id': widget.growId,
        'user_id': userId,
        'image_url': publicUrl,
        'day_number': widget.currentDay,
        'note': '',
      });

      // Reload gallery
      await _loadPhotos();

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📸 Photo added for Day ${widget.currentDay}'),
            backgroundColor: AppTheme.primary.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _confirmDelete(Map<String, dynamic> photo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Photo', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Remove this photo from your grow diary?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textTertiary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deletePhoto(photo);
            },
            child: Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePhoto(Map<String, dynamic> photo) async {
    try {
      await Supabase.instance.client
          .from('grow_photos')
          .delete()
          .eq('id', photo['id']);
      await _loadPhotos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  void _showPhotoDetail(Map<String, dynamic> photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: photo['image_url'] as String? ?? '',
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 200,
                        color: AppTheme.glassBackground,
                        child: const Center(
                          child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 200,
                        color: AppTheme.glassBackground,
                        child: const Icon(
                          Icons.broken_image,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Day ${photo['day_number'] ?? '?'}',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          photo['note'] as String? ?? '',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String imageUrl;
  final int day;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _PhotoTile({
    required this.imageUrl,
    required this.day,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppTheme.glassBackground,
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 1),
                ),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppTheme.glassBackground,
                child: const Icon(
                  Icons.image_outlined,
                  color: AppTheme.textTertiary,
                ),
              ),
            ),
            // Day badge
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'D$day',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
