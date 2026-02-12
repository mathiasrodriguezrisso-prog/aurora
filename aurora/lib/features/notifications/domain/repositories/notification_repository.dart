/// 📁 lib/features/notifications/domain/repositories/notification_repository.dart
/// Interfaz para las operaciones de notificaciones.
library;

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/notification_entity.dart';

abstract class NotificationRepository {
  /// Obtiene la lista de notificaciones del usuario.
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({int page = 1, int limit = 20});

  /// Marca una notificación específica como leída.
  Future<Either<Failure, void>> markAsRead(String id);

  /// Marca todas las notificaciones como leídas.
  Future<Either<Failure, void>> markAllAsRead();

  /// Elimina una notificación.
  Future<Either<Failure, void>> deleteNotification(String id);
}
