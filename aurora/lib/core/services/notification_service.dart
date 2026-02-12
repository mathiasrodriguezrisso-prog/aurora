/// 📁 lib/core/services/notification_service.dart
/// Push notification service using Firebase Cloud Messaging (FCM)
/// and flutter_local_notifications for foreground display.
library;

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  // ── Singleton ──────────────────────────────────────────────
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  /// Global navigator key — set from app_router.dart so we can navigate
  /// from notification taps even without a BuildContext.
  GlobalKey<NavigatorState>? navigatorKey;

  bool _initialized = false;

  // ── Android Channel ────────────────────────────────────────
  static const _channel = AndroidNotificationChannel(
    'aurora_alerts',
    'Aurora Alerts',
    description: 'Grow alerts and Dr. Aurora notifications',
    importance: Importance.high,
  );

  // ── Init ───────────────────────────────────────────────────

  /// Call once at app startup, AFTER Firebase.initializeApp().
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Initialize local notifications plugin
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 2. Request permission (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[Notifications] Auth status: ${settings.authorizationStatus}');
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // 3. Get FCM token and save to Supabase
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(token);

    // 4. Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveToken);

    // 5. Foreground messages → show local notification
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. Background tap → navigate
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _handleNotificationTap(msg.data);
    });

    // 7. App killed + user tapped notification → navigate
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay slightly to ensure router is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage.data);
      });
    }
  }

  // ── Save FCM Token ─────────────────────────────────────────

  Future<void> _saveToken(String token) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('profiles').update({
        'fcm_token': token,
      }).eq('id', userId);

      debugPrint('[Notifications] FCM token saved');
    } catch (e) {
      debugPrint('[Notifications] Failed to save token: $e');
    }
  }

  // ── Foreground Handler ─────────────────────────────────────

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await showLocalNotification(
      title: notification.title ?? 'Aurora',
      body: notification.body ?? '',
      payload: jsonEncode(message.data),
    );
  }

  // ── Navigation from Tap ────────────────────────────────────

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final ctx = navigatorKey?.currentContext;
    if (ctx == null) return;

    switch (type) {
      case 'alert':
        GoRouter.of(ctx).go('/grow'); // climate tab
      case 'task':
        GoRouter.of(ctx).go('/home');
      case 'social':
        final postId = data['post_id'] as String?;
        if (postId != null) {
          GoRouter.of(ctx).go('/pulse/post/$postId');
        } else {
          GoRouter.of(ctx).go('/pulse');
        }
      case 'chat':
        GoRouter.of(ctx).go('/chat');
      default:
        GoRouter.of(ctx).go('/home');
    }
  }

  /// Called when user taps a local notification (foreground).
  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _handleNotificationTap(data);
    } catch (_) {}
  }

  // ── Show Local Notification ────────────────────────────────

  /// Display a notification while the app is in the foreground.
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique ID
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF00E676),
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }
}
