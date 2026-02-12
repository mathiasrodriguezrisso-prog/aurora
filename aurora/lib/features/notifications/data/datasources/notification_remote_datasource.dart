/// 📁 lib/features/notifications/data/datasources/notification_remote_datasource.dart
/// Fuente de datos remota para notificaciones usando Supabase.
library;

import '../../../../core/network/api_client.dart';

abstract class NotificationRemoteDataSource {
  Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 20});
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient _api;

  NotificationRemoteDataSourceImpl(this._api);

  @override
  Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 20}) async {
    final response = await _api.get(
      '/notifications/',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<void> markAsRead(String id) async {
    await _api.post('/notifications/$id/read');
  }

  @override
  Future<void> markAllAsRead() async {
    await _api.post('/notifications/read-all');
  }

  @override
  Future<void> deleteNotification(String id) async {
    await _api.delete('/notifications/$id');
  }
}
