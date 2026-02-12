import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_router.dart';
import 'core/config/app_theme.dart';
import 'core/services/notification_service.dart';

/// Root widget of the Aurora application.
class AuroraApp extends ConsumerWidget {
  const AuroraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Wire navigator key so NotificationService can navigate on tap
    NotificationService.instance.navigatorKey = router.routerDelegate.navigatorKey;

    return MaterialApp.router(
      title: 'Aurora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
