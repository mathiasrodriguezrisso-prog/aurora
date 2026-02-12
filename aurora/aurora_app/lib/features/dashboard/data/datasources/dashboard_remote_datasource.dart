
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardRemoteDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchActiveGrow(String userId) async {
    final response = await _client
        .from('grows')
        .select()
        .eq('user_id', userId)
        .eq('status', 'active')
        .maybeSingle(); // Returns Map or null
    return response;
  }

  Future<List<Map<String, dynamic>>> fetchGrowPlan(String growId) async {
    final response = await _client
        .from('grow_phases')
        .select()
        .eq('grow_id', growId)
        .order('order_index');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchDailyTasks(String growId, String date) async {
    final response = await _client
        .from('daily_tasks')
        .select()
        .eq('grow_id', growId)
        .eq('date', date);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> toggleTaskCompletion(String taskId, bool completed) async {
    await _client
        .from('daily_tasks')
        .update({'completed': completed})
        .eq('id', taskId);
  }

  Future<Map<String, dynamic>?> fetchLatestSensor(String growId) async {
    final response = await _client
        .from('sensor_readings')
        .select()
        .eq('grow_id', growId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return response;
  }
}
