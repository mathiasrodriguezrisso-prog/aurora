import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../shared/services/image_upload_service.dart';
import '../../data/providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  String _experienceLevel = 'beginner';
  String _growStyle = '';
  String? _avatarUrl;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).myProfile;
    _nameController = TextEditingController(text: profile?.displayName ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _locationController = TextEditingController(text: profile?.location ?? '');
    _experienceLevel = profile?.experienceLevel ?? 'beginner';
    _growStyle = profile?.growStyle ?? '';
    _avatarUrl = profile?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploading = true);
    
    try {
      final uploadService = ref.read(imageUploadServiceProvider);
      final url = await uploadService.uploadImage(image.path, 'profiles');
      
      if (mounted) {
        setState(() {
          _avatarUrl = url;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error subiendo imagen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              _buildAppBar(context),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildAvatarPicker(),
                      const SizedBox(height: 32),
                      
                      _buildField('Nombre a mostrar', _nameController, maxLength: 50),
                      const SizedBox(height: 16),
                      
                      _buildField('Biografía', _bioController,
                          maxLength: 250, maxLines: 3),
                      const SizedBox(height: 16),
                      
                      _buildField('Ubicación (Opcional)', _locationController,
                          maxLength: 100),
                      const SizedBox(height: 24),

                      // Experience level
                      _buildSectionLabel('Nivel de Experiencia'),
                      const SizedBox(height: 12),
                      _buildChipSelector(
                        selected: _experienceLevel,
                        options: ['beginner', 'intermediate', 'expert'],
                        onSelected: (v) =>
                            setState(() => _experienceLevel = v),
                      ),
                      const SizedBox(height: 24),

                      // Grow style
                      _buildSectionLabel('Estilo de Cultivo'),
                      const SizedBox(height: 12),
                      _buildChipSelector(
                        selected: _growStyle,
                        options: ['indoor', 'outdoor', 'greenhouse', 'hydro'],
                        onSelected: (v) =>
                            setState(() => _growStyle = v),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppTheme.textSecondary, size: 20),
            onPressed: () => context.pop(),
          ),
          const Text(
            'Editar Perfil',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          _isSaving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                    strokeWidth: 2,
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text(
                    'Guardar',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 54,
            backgroundColor: AppTheme.surface,
            backgroundImage: _avatarUrl != null ? CachedNetworkImageProvider(_avatarUrl!) : null,
            child: _isUploading
                ? const CircularProgressIndicator(color: AppTheme.primary)
                : (_avatarUrl == null
                    ? const Icon(Icons.person_outline, size: 40, color: AppTheme.textTertiary)
                    : null),
          ),
        ),
        GestureDetector(
          onTap: _isUploading ? null : _pickImage,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.surface, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int maxLength = 100,
    int maxLines = 1,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: AppTheme.surface.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: TextField(
            controller: controller,
            maxLength: maxLength,
            maxLines: maxLines,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
              border: InputBorder.none,
              counterStyle: TextStyle(color: AppTheme.textTertiary, fontSize: 10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChipSelector({
    required String selected,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: options.map((option) {
        final isActive = selected.toLowerCase() == option.toLowerCase();
        return GestureDetector(
          onTap: () => onSelected(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primary.withOpacity(0.15)
                  : AppTheme.surface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? AppTheme.primary : AppTheme.glassBorder,
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Text(
              _getSpanishLabel(option),
              style: TextStyle(
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getSpanishLabel(String val) {
    switch (val) {
      case 'beginner': return 'Principiante';
      case 'intermediate': return 'Intermedio';
      case 'expert': return 'Experto';
      case 'indoor': return 'Interior';
      case 'outdoor': return 'Exterior';
      case 'greenhouse': return 'Invernadero';
      case 'hydro': return 'Hidroponía';
      default: return val[0].toUpperCase() + val.substring(1);
    }
  }

  Future<void> _save() async {
    if (_isUploading) return;
    
    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    final success = await ref.read(profileProvider.notifier).updateProfile(
      displayName: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      location: _locationController.text.trim(),
      experienceLevel: _experienceLevel,
      growStyle: _growStyle,
      avatarUrl: _avatarUrl,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: AppTheme.primary,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar el perfil'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }
}
