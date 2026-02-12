import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../models/diagnosis_model.dart';

/// Concrete implementation of [ChatRepository].
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required String message,
    String? growId,
  }) async {
    try {
      final result = await _remoteDataSource.sendMessage(
        message: message,
        growId: growId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessageEntity>>> getHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final result = await _remoteDataSource.getHistory(
        limit: limit,
        offset: offset,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  @override
  Future<Either<Failure, ({String chatResponse, DiagnosisModel? diagnosis})>> sendDiagnosis({
    required String imageUrl,
    String? message,
    String? growId,
  }) async {
    try {
      final response = await _remoteDataSource.sendDiagnosis(
        imageUrl: imageUrl,
        message: message,
        growId: growId,
      );
      
      final chatResponse = response['chat_response'] as String? ?? response['response'] as String? ?? 'Análisis completado';
      DiagnosisModel? diagnosis;
      
      if (response['diagnosis'] != null) {
        diagnosis = DiagnosisModel.fromJson(response['diagnosis'] as Map<String, dynamic>);
      } else {
        // Backend retornó solo texto o fallback, construir diagnóstico básico
        diagnosis = DiagnosisModel.fromTextResponse(chatResponse);
      }
      
      return Right((chatResponse: chatResponse, diagnosis: diagnosis));
    } catch (e) {
      return Left(ServerFailure('Error al enviar diagnóstico: $e'));
    }
  }
}
