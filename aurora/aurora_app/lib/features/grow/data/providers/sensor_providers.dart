
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sensor_reading_model.dart';

// Latest Sensor Provider
final latestSensorProvider = FutureProvider.family.autoDispose<SensorReadingModel?, String>((ref, growId) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('sensor_readings')
      .select()
      .eq('grow_id', growId)
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();

  if (response == null) return null;
  return SensorReadingModel.fromJson(response);
});

// Sensor History Provider
// params: record type alias not supported well in all Dart versions inline, using a simple class or just dynamic
// Using typedef-like record: ({String growId, String range})
final sensorHistoryProvider = FutureProvider.family.autoDispose<List<SensorReadingModel>, ({String growId, String range})>((ref, params) async {
  final supabase = Supabase.instance.client;
  final now = DateTime.now();
  late DateTime startDate;
  
  switch (params.range) {
    case '24h': startDate = now.subtract(const Duration(hours: 24)); break;
    case '7d': startDate = now.subtract(const Duration(days: 7)); break;
    case '30d': startDate = now.subtract(const Duration(days: 30)); break;
    default: startDate = now.subtract(const Duration(hours: 24));
  }

  final response = await supabase
      .from('sensor_readings')
      .select()
      .eq('grow_id', params.growId)
      .gte('created_at', startDate.toIso8601String())
      .order('created_at'); // Ascending for charts

  return (response as List).map((e) => SensorReadingModel.fromJson(e)).toList();
});

// Submit Sensor Reading Provider
final submitSensorReadingProvider = Provider<Future<SensorReadingModel?> Function(String, double, double, double?, double?)>((ref) {
  return (String growId, double temp, double humidity, double? ph, double? ec) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    
    if (userId == null) return null;

    final response = await supabase.from('sensor_readings').insert({
      'grow_id': growId,
      'user_id': userId,
      'temperature': temp,
      'humidity': humidity,
      if (ph != null) 'ph': ph,
      if (ec != null) 'ec': ec,
    }).select().single();

    // Invalidate latest sensor to refresh UI immediately
    ref.invalidate(latestSensorProvider(growId));
    // Also invalidate dashboard sensors if applicable
    ref.invalidate(latestSensorProvider); 
    
    return SensorReadingModel.fromJson(response);
  };
});
