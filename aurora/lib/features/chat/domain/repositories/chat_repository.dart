import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_message_entity.dart';
import '../../data/models/diagnosis_model.dart';

/// Abstract repository for chat operations.
abstract class ChatRepository {
  /// Send a message to Dr. Aurora and receive a response.
  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required String message,
    String? growId,
  });

  /// Load chat history with pagination.
  Future<Either<Failure, List<ChatMessageEntity>>> getHistory({
    int limit = 50,
    int offset = 0,
  });

  /// Uploads an image and gets a diagnosis from AI.
  Future<Either<Failure, ({String chatResponse, DiagnosisModel? diagnosis})>> sendDiagnosis({
    required String imageUrl,
    String? message,
    String? growId,
  });
}
