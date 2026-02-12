import '../../data/models/diagnosis_model.dart';

/// Chat message entity for Dr. Aurora conversations.
class ChatMessageEntity {
  final String id;
  final ChatRole role;
  final String content;
  final ChatMessageMetadata? metadata;
  final DateTime createdAt;

  const ChatMessageEntity({
    required this.id,
    required this.role,
    required this.content,
    this.metadata,
    required this.createdAt,
    this.imageUrl,
    this.diagnosis,
  });

  final String? imageUrl;
  final DiagnosisModel? diagnosis;
}

/// Chat message role.
enum ChatRole {
  user,
  assistant,
  system;

  static ChatRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'user':
        return ChatRole.user;
      case 'assistant':
        return ChatRole.assistant;
      case 'system':
        return ChatRole.system;
      default:
        return ChatRole.user;
    }
  }
}

/// Detected intent type.
enum IntentType {
  question,
  emergency,
  general,
  adjustPlan,
  diagnostics;

  static IntentType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'question':
        return IntentType.question;
      case 'emergency':
        return IntentType.emergency;
      case 'adjust_plan':
        return IntentType.adjustPlan;
      case 'diagnostics':
        return IntentType.diagnostics;
      default:
        return IntentType.general;
    }
  }
}

/// Metadata attached to a chat response.
class ChatMessageMetadata {
  final IntentType intent;
  final bool isEmergency;
  final int tokensUsed;
  final List<String> contextSources;

  const ChatMessageMetadata({
    this.intent = IntentType.general,
    this.isEmergency = false,
    this.tokensUsed = 0,
    this.contextSources = const [],
  });
}
