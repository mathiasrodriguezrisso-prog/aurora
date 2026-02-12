/// 📁 lib/features/notifications/presentation/screens/notification_screen.dart
/// Pantalla de historial de notificaciones con diseño Glassmorphism, 
/// swipe-to-delete y agrupación por fechas.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_providers.dart';
import '../widgets/notification_item_widget.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fondo oscuro profundo
          Container(color: const Color(0xFF0A0A0F)),
          
          // Glow background
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, ref),
                Expanded(
                  child: notificationsAsync.when(
                    data: (notifications) {
                      if (notifications.isEmpty) {
                        return const Center(
                          child: EmptyState(
                            icon: Icons.notifications_off_outlined,
                            title: 'No hay notificaciones',
                            subtitle: 'Te avisaremos cuando pase algo importante',
                          ),
                        );
                      }

                      // Agrupar por fecha
                      final groups = _groupNotifications(notifications);

                      return RefreshIndicator(
                        onRefresh: () => ref.read(notificationListProvider.notifier).refresh(),
                        color: AppTheme.primary,
                        backgroundColor: AppTheme.surface,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 40),
                          itemCount: groups.length,
                          itemBuilder: (context, index) {
                            final item = groups[index];
                            if (item is String) {
                              return _buildDateHeader(item);
                            } else {
                              final notification = item as NotificationEntity;
                              return _buildDismissibleItem(context, ref, notification);
                            }
                          },
                        ),
                      );
                    },
                    loading: () => const ShimmerLoading(),
                    error: (e, __) => Center(
                      child: EmptyState(
                        icon: Icons.error_outline,
                        title: 'Error al cargar',
                        subtitle: e.toString(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          ),
          const Expanded(
            child: Text(
              'Notificaciones',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(notificationListProvider.notifier).markAllAsRead(),
            child: const Text(
              'Marcar todo',
              style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppTheme.textSecondary.withOpacity(0.5),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDismissibleItem(BuildContext context, WidgetRef ref, NotificationEntity notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(notificationListProvider.notifier).deleteNotification(notification.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.redAccent.withOpacity(0.1),
        child: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
      ),
      child: NotificationItemWidget(
        notification: notification,
        onTap: () => _handleTap(context, ref, notification),
      ),
    );
  }

  /// Lógica de agrupación por fecha
  List<dynamic> _groupNotifications(List<NotificationEntity> notifications) {
    final List<dynamic> items = [];
    String? lastGroup;

    for (var n in notifications) {
      final String group = _getDateLabel(n.createdAt);
      if (group != lastGroup) {
        items.add(group);
        lastGroup = group;
      }
      items.add(n);
    }
    return items;
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Hoy';
    } else if (notificationDate == yesterday) {
      return 'Ayer';
    } else if (now.difference(notificationDate).inDays < 7) {
      // Nombre del día: Lunes, Martes...
      return DateFormat('EEEE', 'es').format(date);
    } else {
      // Fecha completa: 12 de Febrero
      return DateFormat('d \'de\' MMMM', 'es').format(date);
    }
  }

  void _handleTap(BuildContext context, WidgetRef ref, NotificationEntity notification) {
    ref.read(notificationListProvider.notifier).markAsRead(notification.id);

    final type = notification.type;
    final data = notification.data ?? {};

    switch (type) {
      case 'task':
        context.go('/home');
      case 'alert':
        context.go('/grow');
      case 'social':
        final postId = data['post_id'];
        if (postId != null) {
          context.push('/feed/post/$postId');
        } else {
          context.go('/feed');
        }
      case 'chat':
        context.push('/chat');
      default:
        break;
    }
  }
}
