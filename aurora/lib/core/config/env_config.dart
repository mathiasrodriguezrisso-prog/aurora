/// 📁 lib/core/config/env_config.dart
/// Centralized environment configuration for Aurora app.
/// Reads from compile-time environment variables (--dart-define)
/// with smart defaults for development.
library;

import 'dart:io' show Platform;

/// Supported environments.
enum AppEnvironment { development, staging, production }

/// Centralized configuration — reads from `--dart-define` or falls back
/// to development defaults.
class EnvConfig {
  EnvConfig._();

  // ── Environment ──────────────────────────────────────────────

  static const String _envString = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static AppEnvironment get environment {
    switch (_envString) {
      case 'production':
        return AppEnvironment.production;
      case 'staging':
        return AppEnvironment.staging;
      default:
        return AppEnvironment.development;
    }
  }

  static bool get isDevelopment => environment == AppEnvironment.development;
  static bool get isProduction => environment == AppEnvironment.production;

  // ── Backend API ──────────────────────────────────────────────

  static const String _backendHost = String.fromEnvironment(
    'BACKEND_HOST',
    defaultValue: '',
  );

  static const String _backendPort = String.fromEnvironment(
    'BACKEND_PORT',
    defaultValue: '8000',
  );

  /// API base URL, smart-detecting Android emulator (10.0.2.2).
  static String get apiBaseUrl {
    if (_backendHost.isNotEmpty) {
      return 'http://$_backendHost:$_backendPort';
    }

    switch (environment) {
      case AppEnvironment.production:
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://api.aurora-app.com',
        );
      case AppEnvironment.staging:
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://staging-api.aurora-app.com',
        );
      case AppEnvironment.development:
        return 'http://${_devHost}:$_backendPort';
    }
  }

  /// In dev, we use the local network IP for physical devices.
  /// If running on emulator, 10.0.2.2 might still work for Android,
  /// but 192.168.1.105 is safer for physical devices.
  static String get _devHost {
    // ⚠️ HARDCODED IP FOR PHYSICAL DEVICE DEBUGGING
    // Use '10.0.2.2' ONLY if using Android Emulator.
    // Use 'localhost' ONLY if using iOS Simulator.
    return '192.168.1.105'; 
  }

  // ── Supabase ─────────────────────────────────────────────────

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  // ── Feature Flags ────────────────────────────────────────────

  static const bool enableOfflineMode = true;
  static const int maxPlantsPerGrow = 12;
  static const int maxActiveGrowsFree = 1;
  static const int maxActiveGrowsPro = -1; // Unlimited

  // ── Timeouts ─────────────────────────────────────────────────

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
}
