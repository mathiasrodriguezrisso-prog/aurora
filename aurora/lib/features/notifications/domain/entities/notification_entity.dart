/// 📁 lib/features/notifications/domain/entities/notification_entity.dart
/// Entidad de negocio para representar una notificación en el frontend.
library;

class NotificationEntity {
  final String id;
  final String type; // 'task', 'alert', 'social', 'system'
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
  });
}
