/// 📁 lib/features/notifications/domain/usecases/delete_notification.dart
/// Caso de uso para eliminar una notificación.
library;

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/notification_repository.dart';

class DeleteNotification {
  final NotificationRepository repository;

  DeleteNotification(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.deleteNotification(id);
  }
}
