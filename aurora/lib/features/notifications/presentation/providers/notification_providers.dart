/// 📁 lib/features/notifications/presentation/providers/notification_providers.dart
/// Providers de Riverpod para gestionar el estado de las notificaciones.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/mark_notification_as_read.dart';
import '../../domain/usecases/delete_notification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider para el DataSource
final notificationRemoteDataSourceProvider = Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSourceImpl(Supabase.instance.client);
});

/// Provider para el Repositorio
final notificationRepositoryProvider = Provider<NotificationRepositoryImpl>((ref) {
  final dataSource = ref.watch(notificationRemoteDataSourceProvider);
  return NotificationRepositoryImpl(dataSource);
});

/// Provider para el Estado de las Notificaciones
final notificationListProvider = AsyncNotifierProvider<NotificationListNotifier, List<NotificationEntity>>(() {
  return NotificationListNotifier();
});

class NotificationListNotifier extends AsyncNotifier<List<NotificationEntity>> {
  @override
  Future<List<NotificationEntity>> build() async {
    final getNotifications = GetNotifications(ref.watch(notificationRepositoryProvider));
    final result = await getNotifications();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (notifications) => notifications,
    );
  }

  /// Actualización optimista para marcar como leída.
  Future<void> markAsRead(String id) async {
    final previousState = state.value;
    if (previousState == null) return;

    // 1. Actualización optimista local
    state = AsyncData(previousState.map((n) {
      if (n.id == id) {
        return NotificationEntity(
          id: n.id,
          type: n.type,
          title: n.title,
          body: n.body,
          data: n.data,
          isRead: true,
          createdAt: n.createdAt,
        );
      }
      return n;
    }).toList());

    // 2. Llamada asíncrona
    final markAsReadUsecase = MarkNotificationAsRead(ref.watch(notificationRepositoryProvider));
    final result = await markAsReadUsecase(id);
    
    // 3. Rollback si falla
    result.fold(
      (failure) {
        state = AsyncData(previousState);
      },
      (_) => null,
    );
  }

  Future<void> markAllAsRead() async {
    final previousState = state.value;
    if (previousState == null) return;

    // Optimista
    state = AsyncData(previousState.map((n) {
      return NotificationEntity(
        id: n.id,
        type: n.type,
        title: n.title,
        body: n.body,
        data: n.data,
        isRead: true,
        createdAt: n.createdAt,
      );
    }).toList());

    final repository = ref.watch(notificationRepositoryProvider);
    final result = await repository.markAllAsRead();

    result.fold(
      (failure) {
        state = AsyncData(previousState);
      },
      (_) => null,
    );
  }

  /// Actualización optimista para eliminar.
  Future<void> deleteNotification(String id) async {
    final previousState = state.value;
    if (previousState == null) return;

    // 1. Actualización optimista (remover de la lista)
    state = AsyncData(previousState.where((n) => n.id != id).toList());

    // 2. Llamada asíncrona
    final deleteUsecase = DeleteNotification(ref.watch(notificationRepositoryProvider));
    final result = await deleteUsecase(id);

    // 3. Rollback si falla
    result.fold(
      (failure) {
        state = AsyncData(previousState);
      },
      (_) => null,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

/// Provider para el conteo de no leídas (Renombrado como pidió el USER)
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationListProvider).value ?? [];
  return notifications.where((n) => !n.isRead).length;
});
