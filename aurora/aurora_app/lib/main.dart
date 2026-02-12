
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/config/app_theme.dart';
import 'core/config/app_router.dart';
import 'core/config/env_config.dart';
import 'core/services/notification_service.dart';

// Entry point
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Env
  await EnvConfig.load();

  // Initialize Firebase (if configured)
  try {
    // Check if firebase options are available in firebase_options.dart if generated
    // For now, we use default or manual config if headers provided.
    // If not using google-services.json yet, this might throw if not configured.
    // We wrap in try-catch to allow app to run without push for now if needed.
    await Firebase.initializeApp();
    final notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e) {
    print("Firebase init error (expected if not configured): $e");
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: AuroraApp()));
}

class AuroraApp extends ConsumerWidget {
  const AuroraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Aurora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
