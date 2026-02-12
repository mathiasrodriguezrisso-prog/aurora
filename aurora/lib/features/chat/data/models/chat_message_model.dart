import '../../data/models/diagnosis_model.dart';
import '../../domain/entities/chat_message_entity.dart';

/// JSON serialization model for chat messages.
class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.role,
    required super.content,
    super.metadata,
    required super.createdAt,
    super.imageUrl,
    super.diagnosis,
  });

  /// Create from JSON map (API response).
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    ChatMessageMetadata? metadata;
    if (json['metadata'] != null && json['metadata'] is Map) {
      final m = json['metadata'] as Map<String, dynamic>;
      metadata = ChatMessageMetadata(
        intent: IntentType.fromString(m['intent'] ?? 'general'),
        isEmergency: m['is_emergency'] ?? false,
        tokensUsed: m['tokens_used'] ?? 0,
        contextSources: (m['context_sources'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );
    }

    return ChatMessageModel(
      id: json['id'] ?? '',
      role: ChatRole.fromString(json['role'] ?? 'assistant'),
      content: json['content'] ?? '',
      metadata: metadata,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      imageUrl: json['image_url'],
      diagnosis: json['diagnosis'] != null
          ? DiagnosisModel.fromJson(json['diagnosis'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON map.
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      if (imageUrl != null) 'image_url': imageUrl,
      if (diagnosis != null) 'diagnosis': diagnosis, // DiagnosisModel should have toJson if needed, but for now we store it
      if (metadata != null)
        'metadata': {
          'intent': metadata!.intent.name,
          'is_emergency': metadata!.isEmergency,
          'tokens_used': metadata!.tokensUsed,
          'context_sources': metadata!.contextSources,
        },
    };
  }
}
