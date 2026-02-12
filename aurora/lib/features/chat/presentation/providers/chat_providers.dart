import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/services/image_upload_service.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/models/diagnosis_model.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

// ===========================================
// DEPENDENCY INJECTION
// ===========================================

/// Proporciona el datasource remoto de chat.
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSourceImpl(ref.watch(apiClientProvider));
});


/// Provides the chat repository.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepositoryImpl(ref.watch(chatRemoteDataSourceProvider));
});

// ===========================================
// CHAT STATE
// ===========================================

/// Possible chat UI states.
enum ChatStatus {
  initial,
  loadingHistory,
  ready,
  sending,
  error,
}

/// Chat state class.
class ChatState {
  final ChatStatus status;
  final List<ChatMessageEntity> messages;
  final String? errorMessage;
  final bool hasMore;

  final bool isDiagnosing;
  final DiagnosisModel? lastDiagnosis;
  final String? diagnosisImageUrl;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.errorMessage,
    this.hasMore = true,
    this.isDiagnosing = false,
    this.lastDiagnosis,
    this.diagnosisImageUrl,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessageEntity>? messages,
    String? errorMessage,
    bool? hasMore,
    bool? isDiagnosing,
    DiagnosisModel? lastDiagnosis,
    String? diagnosisImageUrl,
    bool clearError = false,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasMore: hasMore ?? this.hasMore,
      isDiagnosing: isDiagnosing ?? this.isDiagnosing,
      lastDiagnosis: lastDiagnosis ?? this.lastDiagnosis,
      diagnosisImageUrl: diagnosisImageUrl ?? this.diagnosisImageUrl,
    );
  }

  bool get isLoading =>
      status == ChatStatus.loadingHistory || status == ChatStatus.sending;
  bool get isSending => status == ChatStatus.sending;
  bool get isEmpty =>
      status == ChatStatus.ready && messages.isEmpty;
}

// ===========================================
// CHAT NOTIFIER
// ===========================================

/// StateNotifier for managing chat state.
class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repository;
  final ImageUploadService _imageUploadService;

  ChatNotifier(this._repository, this._imageUploadService) : super(const ChatState());

  /// Load chat history from the backend.
  Future<void> loadHistory({bool refresh = false}) async {
    if (state.status == ChatStatus.loadingHistory) return;

    state = state.copyWith(status: ChatStatus.loadingHistory, clearError: true);

    final result = await _repository.getHistory(
      limit: 50,
      offset: 0,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: failure.message,
      ),
      (messages) => state = state.copyWith(
        status: ChatStatus.ready,
        messages: messages,
        hasMore: messages.length >= 50,
      ),
    );
  }

  Future<void> sendDiagnosisImage({
    required File imageFile,
    String? message,
    String? growId,
  }) async {
    state = state.copyWith(isDiagnosing: true, errorMessage: null);

    try {
      // 1. Subir imagen
      final imageUrl = await _imageUploadService.uploadImage(
        imageFile: imageFile,
        bucket: 'chat-images',
        path: 'diagnosis/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // 2. Agregar mensaje del usuario con la imagen (optimista)
      final userMsg = ChatMessageEntity(
        id: DateTime.now().toString(),
        role: ChatRole.user,
        content: message ?? 'Diagnóstico solicitado',
        createdAt: DateTime.now(),
        imageUrl: imageUrl, // Asumiendo que ChatMessageEntity tiene este campo o lo agregaremos
      );
      
      state = state.copyWith(
        messages: [...state.messages, userMsg],
        diagnosisImageUrl: imageUrl,
      );

      // 3. Enviar a API de diagnóstico
      final result = await _repository.sendDiagnosis(
        imageUrl: imageUrl,
        message: message,
        growId: growId,
      );

      result.fold(
        (failure) => state = state.copyWith(
          isDiagnosing: false,
          errorMessage: failure.message,
        ),
        (response) {
          final aiMsg = ChatMessageEntity(
            id: DateTime.now().toString(),
            role: ChatRole.assistant,
            content: response.chatResponse,
            createdAt: DateTime.now(),
            imageUrl: imageUrl, // Pass image analyzed
            diagnosis: response.diagnosis,
          );

          state = state.copyWith(
            isDiagnosing: false,
            messages: [...state.messages, aiMsg],
            lastDiagnosis: response.diagnosis, // Still keep for immediate UI effects if needed
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isDiagnosing: false,
        errorMessage: 'Error enviando imagen: $e',
      );
    }
  }

  /// Send a message to Dr. Aurora.
  Future<void> sendMessage(String text, {String? growId}) async {
    if (text.trim().isEmpty) return;

    // Optimistically add user message
    final userMessage = ChatMessageEntity(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.user,
      content: text.trim(),
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      status: ChatStatus.sending,
      messages: [...state.messages, userMessage],
      clearError: true,
    );

    final result = await _repository.sendMessage(
      message: text.trim(),
      growId: growId,
    );

    result.fold(
      (failure) => state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: failure.message,
      ),
      (response) {
        // Replace temp user message with real one and add assistant response
        final updated = state.messages
            .where((m) => m.id != userMessage.id)
            .toList();

        // Re-add user message with proper timestamp consideration
        updated.add(userMessage);
        updated.add(response);

        state = state.copyWith(
          status: ChatStatus.ready,
          messages: updated,
        );
      },
    );
  }

  /// Clear error state.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// ===========================================
// MAIN CHAT PROVIDER
// ===========================================

/// Main chat provider.
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final imageUploadService = ref.watch(imageUploadServiceProvider);
  return ChatNotifier(repository, imageUploadService);
});

/// Convenience provider for chat messages list.
final chatMessagesProvider = Provider<List<ChatMessageEntity>>((ref) {
  return ref.watch(chatProvider).messages;
});

/// Convenience provider for chat status.
final chatStatusProvider = Provider<ChatStatus>((ref) {
  return ref.watch(chatProvider).status;
});
