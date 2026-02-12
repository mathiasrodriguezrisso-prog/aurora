/// Datasource remoto para Dr. Aurora Chat.
/// Migrado a usar ApiClient (Dio) con JWT automático.
library;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/chat_message_model.dart';

/// Interfaz del datasource remoto de Chat.
abstract class ChatRemoteDataSource {
  /// Enviar un mensaje y obtener la respuesta de Dr. Aurora.
  Future<ChatMessageModel> sendMessage({
    required String message,
    String? growId,
  });

  /// Cargar historial de chat paginado.
  Future<List<ChatMessageModel>> getHistory({
    int limit = 50,
    int offset = 0,
  });

  /// Enviar imagen para diagnóstico.
  Future<Map<String, dynamic>> sendDiagnosis({
    required String imageUrl,
    String? message,
    String? growId,
  });
}

/// Implementación usando ApiClient (Dio).
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient _api;

  ChatRemoteDataSourceImpl(this._api);

  @override
  Future<ChatMessageModel> sendMessage({
    required String message,
    String? growId,
  }) async {
    try {
      final body = <String, dynamic>{
        'message': message,
      };
      if (growId != null) {
        body['grow_id'] = growId;
      }

      final response = await _api.post<Map<String, dynamic>>(
        '/api/v1/chat/message',
        data: body,
      );

      return ChatMessageModel.fromJson(response.data!);
    } on ApiException catch (e) {
      if (e.isAuthError) {
        throw AuthException('Sesión expirada. Inicia sesión nuevamente.');
      }
      throw ServerException(e.message, statusCode: e.statusCode);
    }
  }

  @override
  Future<List<ChatMessageModel>> getHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/v1/chat/history',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final data = response.data!;
      final messages = (data['messages'] as List<dynamic>?) ?? [];
      return messages
          .map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      if (e.isAuthError) {
        throw AuthException('Sesión expirada. Inicia sesión nuevamente.');
      }
      throw ServerException(e.message, statusCode: e.statusCode);
    }
  }
  @override
  Future<Map<String, dynamic>> sendDiagnosis({
    required String imageUrl,
    String? message,
    String? growId,
  }) async {
    try {
      final body = <String, dynamic>{
        'image_url': imageUrl,
      };
      if (message != null) body['message'] = message;
      if (growId != null) body['grow_id'] = growId;

      final response = await _api.post<Map<String, dynamic>>(
        '/api/v1/chat/diagnose',
        data: body,
      );

      return response.data!;
    } on ApiException catch (e) {
      // Fallback: Si el endpoint de diagnóstico falla (ej: 404),
      // intentar enviar como mensaje normal con la imagen adjunta en texto.
      if (e.statusCode == 404) {
         final fallbackMsg = '${message ?? "Analiza esta imagen por favor"}\n\n[Imagen adjunta: $imageUrl]';
         final chatMsg = await sendMessage(message: fallbackMsg, growId: growId);
         // Convertir a formato esperado por repositorio
         return {
           'chat_response': chatMsg.content,
           'diagnosis': null, // No estructurado
         };
      }
      
      if (e.isAuthError) {
        throw AuthException('Sesión expirada. Inicia sesión nuevamente.');
      }
      throw ServerException(e.message, statusCode: e.statusCode);
    }
  }
}
