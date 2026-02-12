
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/empty_state.dart';

class GrowGallery extends ConsumerStatefulWidget {
  final String growId;
  const GrowGallery({super.key, required this.growId});

  @override
  ConsumerState<GrowGallery> createState() => _GrowGalleryState();
}

class _GrowGalleryState extends ConsumerState<GrowGallery> {
  List<String> _photoUrls = [];
  bool _uploading = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final supabase = Supabase.instance.client;
      // List files from storage bucket 'grow-photos' with prefix growId
      // Note: Bucket must depend on growId or have folders
      final List<FileObject> objects = await supabase.storage.from('grow-photos').list(path: widget.growId);
      
      final urls = objects.map((obj) {
        return supabase.storage.from('grow-photos').getPublicUrl('${widget.growId}/${obj.name}');
      }).toList();

      if (mounted) {
        setState(() {
          _photoUrls = urls;
          _loading = false;
        });
      }
    } catch (e) {
      // If bucket doesn't exist or empty, just show empty
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final ImagePicker picker = ImagePicker();
    
    // Show modal to choose source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.white),
            title: const Text("Take Photo", style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.white),
            title: const Text("Choose from Gallery", style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source == null) return;

    final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
    if (image == null) return;

    setState(() => _uploading = true);

    try {
      final supabase = Supabase.instance.client;
      final bytes = await image.readAsBytes();
      final fileName = '${widget.growId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await supabase.storage.from('grow-photos').uploadBinary(fileName, bytes);
      final url = supabase.storage.from('grow-photos').getPublicUrl(fileName);

      if (mounted) {
        setState(() {
          _photoUrls.add(url);
          _uploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: AppTheme.error,
        ));
      }
    }
  }

  void _showFullscreen(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: SizedBox.expand(
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: AppTheme.primary,
        onPressed: _uploading ? null : _pickAndUpload,
        child: _uploading 
          ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: Colors.black))
          : const Icon(Icons.add_a_photo, color: Colors.black),
      ),
      body: _photoUrls.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EmptyState(icon: Icons.camera_alt_outlined, message: "No photos yet 📸"),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
                  onPressed: _pickAndUpload,
                  child: const Text("Add First Photo"),
                ),
              ],
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photoUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showFullscreen(context, _photoUrls[index]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: _photoUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.white10),
                    errorWidget: (_, __, ___) => Container(
                      color: Colors.white10,
                      child: const Icon(Icons.broken_image, color: Colors.white30),
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }
}
