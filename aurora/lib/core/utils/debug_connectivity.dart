import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../config/env_config.dart';

/// Test backend connectivity.
/// Call this from a button onPressed event:
/// 
/// ```dart
/// ElevatedButton(
///   onPressed: () => DebugConnectivity.testConnection(context, ref),
///   child: Text('Test Connection'),
/// )
/// ```
class DebugConnectivity {
  static Future<void> testConnection(BuildContext context, WidgetRef ref) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      debugPrint('🔌 Connecting to: ${EnvConfig.apiBaseUrl}...');
      
      // Use efficient health check endpoint
      final response = await apiClient.get('/api/v1/health');
      
      debugPrint('🔌 ✅ Success: ${response.statusCode}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Connected to ${EnvConfig.apiBaseUrl}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('🔌 ❌ Failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
