/// 📁 lib/features/dashboard/data/datasources/dashboard_remote_datasource.dart
/// Remote data source for dashboard — queries Supabase directly
/// for active grow, daily tasks, sensor readings, and grow plan.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Data source for dashboard queries using Supabase client.
class DashboardRemoteDataSource {
  final SupabaseClient _client;

  DashboardRemoteDataSource({required SupabaseClient client}) : _client = client;

  /// Fetch the user's active grow (status = 'active').
  Future<Map<String, dynamic>?> fetchActiveGrow(String userId) async {
    try {
      final response = await _client
          .from('grows')
          .select('*, plants(*)')
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      throw DashboardException('Failed to fetch active grow: $e');
    }
  }

  /// Fetch today's daily tasks for a grow.
  Future<List<Map<String, dynamic>>> fetchDailyTasks(
    String growId,
    DateTime date,
  ) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final response = await _client
          .from('daily_tasks')
          .select()
          .eq('grow_id', growId)
          .eq('scheduled_date', dateStr)
          .order('priority', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw DashboardException('Failed to fetch daily tasks: $e');
    }
  }

  /// Fetch the latest sensor reading for a grow.
  Future<Map<String, dynamic>?> fetchLatestSensorData(String growId) async {
    try {
      final response = await _client
          .from('sensor_readings')
          .select()
          .eq('grow_id', growId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      throw DashboardException('Failed to fetch sensor data: $e');
    }
  }

  /// Fetch grow phases and events for the grow plan.
  Future<Map<String, dynamic>> fetchGrowPlan(String growId) async {
    try {
      final phases = await _client
          .from('grow_phases')
          .select('*, grow_events(*)')
          .eq('grow_id', growId)
          .order('phase_order', ascending: true);

      return {
        'phases': List<Map<String, dynamic>>.from(phases),
      };
    } catch (e) {
      throw DashboardException('Failed to fetch grow plan: $e');
    }
  }

  /// Fetch the user's profile data.
  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw DashboardException('Failed to fetch profile: $e');
    }
  }

  /// Fetch the latest Dr. Aurora proactive tip.
  Future<Map<String, dynamic>?> fetchLatestAuroraTip(String userId) async {
    try {
      final response = await _client
          .from('chat_messages')
          .select()
          .eq('user_id', userId)
          .eq('role', 'assistant')
          .eq('is_proactive', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response;
    } catch (e) {
      // Non-critical, return null
      return null;
    }
  }

  /// Toggle a daily task's completion status.
  Future<void> toggleTaskCompletion(String taskId, bool completed) async {
    try {
      await _client.from('daily_tasks').update({
        'is_completed': completed,
        'completed_at': completed ? DateTime.now().toIso8601String() : null,
      }).eq('id', taskId);
    } catch (e) {
      throw DashboardException('Failed to update task: $e');
    }
  }
}

/// Exception for dashboard operations.
class DashboardException implements Exception {
  final String message;
  const DashboardException(this.message);

  @override
  String toString() => 'DashboardException: $message';
}

/// Provider for the dashboard data source.
final dashboardRemoteDataSourceProvider =
    Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSource(
    client: Supabase.instance.client,
  );
});
