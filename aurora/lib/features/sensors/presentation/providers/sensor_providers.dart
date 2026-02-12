/// 📁 lib/features/sensors/presentation/providers/sensor_providers.dart
/// Riverpod providers for sensor readings — real-time latest + history.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/sensor_reading_model.dart';

// ============================================
// Supabase client
// ============================================

final _sbProvider = Provider<SupabaseClient>((_) => Supabase.instance.client);

// ============================================
// Latest reading for a grow
// ============================================

/// Fetches the most recent sensor reading for a given grow ID.
final latestSensorProvider =
    FutureProvider.family<SensorReadingModel?, String>((ref, growId) async {
  final sb = ref.read(_sbProvider);
  final response = await sb
      .from('sensor_readings')
      .select()
      .eq('grow_id', growId)
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();

  if (response == null) return null;
  return SensorReadingModel.fromJson(response);
});

// ============================================
// Sensor history for charts
// ============================================

/// Fetches sensor history for a given grow ID with configurable limit.
final sensorHistoryProvider = FutureProvider.family<List<SensorReadingModel>,
    ({String growId, int limit})>((ref, params) async {
  final sb = ref.read(_sbProvider);
  final response = await sb
      .from('sensor_readings')
      .select()
      .eq('grow_id', params.growId)
      .order('created_at', ascending: true)
      .limit(params.limit);

  return (response as List)
      .map((r) => SensorReadingModel.fromJson(r as Map<String, dynamic>))
      .toList();
});

// ============================================
// Real-time sensor stream (Supabase Realtime)
// ============================================

/// Streams live sensor updates for a grow via Supabase Realtime.
final liveSensorStreamProvider =
    StreamProvider.family<SensorReadingModel, String>((ref, growId) {
  final sb = ref.read(_sbProvider);

  return sb
      .from('sensor_readings')
      .stream(primaryKey: ['id'])
      .eq('grow_id', growId)
      .order('created_at', ascending: false)
      .limit(1)
      .map((rows) {
        if (rows.isEmpty) {
          throw Exception('No sensor data');
        }
        return SensorReadingModel.fromJson(rows.first);
      });
});
