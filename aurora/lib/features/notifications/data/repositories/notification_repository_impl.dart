/// 📁 lib/features/notifications/data/repositories/notification_repository_impl.dart
/// Implementación de NotificationRepository interactuando con data sources.
library;

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({int page = 1, int limit = 20}) async {
    try {
      final data = await remoteDataSource.getNotifications(page: page, limit: limit);
      final rawNotifications = data['notifications'] as List? ?? [];
      final notifications = rawNotifications
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
      return Right(notifications);
    } catch (e) {
      return Left(ServerFailure('Error al obtener notificaciones: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String id) async {
    try {
      await remoteDataSource.markAsRead(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al marcar notificación como leída: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    try {
      await remoteDataSource.markAllAsRead();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al marcar todas las notificaciones como leídas: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String id) async {
    try {
      await remoteDataSource.deleteNotification(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Error al eliminar notificación: $e'));
    }
  }
}
