/// 📁 lib/features/chat/presentation/screens/chat_screen.dart
/// Dr. Aurora AI chat screen with quick actions, photo diagnosis,
/// action chips, and animated avatar states.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/config/app_theme.dart';
import 'dart:io';
import '../../data/chat_suggestions.dart';
import '../../data/models/diagnosis_model.dart';
import '../../../grow/presentation/providers/grow_providers.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../providers/chat_providers.dart';
import '../widgets/diagnostics_card.dart';
import '../widgets/diagnosis_detail_sheet.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/dr_aurora_avatar.dart';
import '../widgets/action_chips.dart';
import '../widgets/diagnosis_detail_sheet.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chatProvider.notifier).loadHistory());
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  AvatarState get _currentAvatarState {
    final status = ref.read(chatProvider).status;
    if (status == ChatStatus.sending) return AvatarState.thinking;
    // Check last message for emergency
    final msgs = ref.read(chatProvider).messages;
    if (msgs.isNotEmpty && msgs.last.metadata?.isEmergency == true) {
      return AvatarState.alert;
    }
    return AvatarState.normal;
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // Auto-scroll when messages change or sending/diagnosing status changes
    ref.listen(chatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length ||
          prev?.isSending != next.isSending ||
          prev?.isDiagnosing != next.isDiagnosing) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            DrAuroraAvatar(size: 32, state: _currentAvatarState),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dr. Aurora',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  chatState.isDiagnosing 
                      ? 'Analizando planta...' 
                      : (chatState.isSending ? 'Escribiendo...' : 'AI Cultivation Expert'),
                  style: TextStyle(
                    color: chatState.isSending
                        ? AppTheme.secondary
                        : AppTheme.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: chatState.status == ChatStatus.loadingHistory
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : chatState.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: chatState.messages.length + (chatState.isSending || chatState.isDiagnosing ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chatState.messages.length) {
                             return _buildTypingIndicator(chatState.isDiagnosing);
                          }
                          final message = chatState.messages[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ChatBubble(message: message),
                              // Show Diagnostics Card if available in the message
                              if (message.diagnosis != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                                  child: DiagnosticsCard(
                                    diagnosis: message.diagnosis!,
                                    imageUrl: message.imageUrl,
                                    onShowDetails: () => _showDiagnosisDetails(
                                      message.diagnosis!,
                                      message.imageUrl,
                                    ),
                                  ),
                                ),
                              // Show action chips after assistant responses
                              if (message.role == ChatRole.assistant &&
                                  index == chatState.messages.length - 1 &&
                                  !chatState.isSending && !chatState.isDiagnosing)
                                _buildResponseActionChips(message),
                            ],
                          );
                        },
                      ),
          ),

          // Quick actions row
          _buildQuickActions(),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DrAuroraAvatar(size: 64)
              .animate()
              .fadeIn(duration: 600.ms)
              .scaleXY(begin: 0.8, end: 1.0, duration: 600.ms),
          const SizedBox(height: 16),
          Text(
            'Hi! I\'m Dr. Aurora 🌿',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about your grow.\nI can diagnose problems, adjust plans,\nand analyze photos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 24),
          // Starter prompts
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _StarterPrompt(
                label: '🌡️ My plant looks droopy',
                onTap: () => _sendMessage('My plant looks droopy, what should I check?'),
              ),
              _StarterPrompt(
                label: '💡 Sugerencia rápida', // Dynamic text?
                onTap: () {
                   final growState = ref.read(activeGrowProvider);
                   final phase = growState.activeGrow?.currentPhase;
                   final suggestion = ChatSuggestions.getSuggestions(phase: phase).first;
                   _sendMessage(suggestion);
                },
              ),
              _StarterPrompt(
                label: '📸 Diagnosticar Planta',
                onTap: () => _pickPhotoForDiagnosis(),
              ),
            ],
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  /// Action chips contextual to the last assistant response.
  Widget _buildResponseActionChips(ChatMessageEntity message) {
    final intent = message.metadata?.intent;
    final chips = <({String label, VoidCallback onTap})>[];

    // Always offer diagnostic and photo
    chips.add((label: '📊 Show Diagnostics', onTap: _showDiagnostics));

    if (intent == IntentType.diagnostics || intent == IntentType.emergency) {
      chips.add((label: '📸 Take Photo', onTap: _pickPhotoForDiagnosis));
      chips.add((label: '🔧 Adjust Plan', onTap: () => _sendMessage('Adjust my grow plan based on this.')));
    } else if (intent == IntentType.adjustPlan) {
      chips.add((label: '✅ Apply Changes', onTap: () => _sendMessage('Apply these changes to my plan.')));
    } else {
      chips.add((label: '📸 Take Photo', onTap: _pickPhotoForDiagnosis));
    }

    return Padding(
      padding: const EdgeInsets.only(left: 48, top: 4, bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: chips.map((c) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  c.onTap();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    c.label,
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildTypingIndicator(bool isDiagnosing) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          const DrAuroraAvatar(size: 28, state: AvatarState.thinking),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Container(
                  width: 6,
                  height: 6,
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withValues(alpha: 0.5),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(
                      delay: Duration(milliseconds: i * 200),
                      duration: 400.ms,
                    )
                    .scaleXY(begin: 0.6, end: 1.0, duration: 400.ms);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ActionChips(
        onDiagnostics: _pickPhotoForDiagnosis,
        onAdjustPlan: () => _sendMessage('Ajusta mi plan de cultivo actual.'),
        onTakePhoto: _pickPhotoForDiagnosis,
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12, 8, 8,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.glassBorder)),
      ),
      child: Row(
        children: [
          // Photo button
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: AppTheme.textTertiary, size: 22),
            onPressed: _pickPhotoForDiagnosis,
          ),

          // Text input
          Expanded(
            child: TextField(
              controller: _inputController,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ask Dr. Aurora…',
                hintStyle: TextStyle(color: AppTheme.textTertiary, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppTheme.glassBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppTheme.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppTheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                fillColor: AppTheme.glassBackground,
                filled: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 6),

          // Send button
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.send_rounded, color: AppTheme.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSend() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    _sendMessage(text);
  }

  void _sendMessage(String text) {
    HapticFeedback.lightImpact();
    ref.read(chatProvider.notifier).sendMessage(text);
  }
  void _showDiagnosisDetails(DiagnosisModel diagnosis, String? imageUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DiagnosisDetailSheet(diagnosis: diagnosis, imageUrl: imageUrl),
    );
  }

  void _showDiagnostics() {
    _pickPhotoForDiagnosis();
  }

  Future<void> _pickPhotoForDiagnosis() async {
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
            const Text(
              'Photo Diagnosis',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Take or select a photo for Dr. Aurora to analyze',
              style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
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
              subtitle: Text('Choose an existing photo', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
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
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked == null) return;

      final growState = ref.read(activeGrowProvider);
      final growId = growState.activeGrow?.id;

      if (mounted) {
        // Show snackbar immediately
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Subiendo y analizando imagen...'),
            backgroundColor: AppTheme.primary.withOpacity(0.9),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await ref.read(chatProvider.notifier).sendDiagnosisImage(
        imageFile: File(picked.path),
        growId: growId,
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// ============================================
// Starter Prompt Chip
// ============================================

class _StarterPrompt extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StarterPrompt({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
