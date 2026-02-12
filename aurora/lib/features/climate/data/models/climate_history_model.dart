/// Modelo de historial climático (Data Layer).
library;

import '../../domain/entities/climate_history_entity.dart';
import 'climate_reading_model.dart';

class ClimateHistoryModel extends ClimateHistoryEntity {
  const ClimateHistoryModel({
    required super.readings,
    required super.stats,
  });

  factory ClimateHistoryModel.fromJson(Map<String, dynamic> json) {
    return ClimateHistoryModel(
      readings: (json['readings'] as List)
          .map((e) => ClimateReadingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      stats: _StatsModel.fromJson(json['stats'] as Map<String, dynamic>),
    );
  }
}

class _StatsModel extends ClimateStatsEntity {
  const _StatsModel({
    required super.avgTemp,
    required super.minTemp,
    required super.maxTemp,
    required super.avgHumidity,
    required super.minHumidity,
    required super.maxHumidity,
    required super.avgVpd,
    required super.minVpd,
    required super.maxVpd,
    super.avgPh,
    super.avgEc,
    required super.readingsCount,
  });

  factory _StatsModel.fromJson(Map<String, dynamic> json) {
    return _StatsModel(
      avgTemp: (json['avg_temp'] as num).toDouble(),
      minTemp: (json['min_temp'] as num).toDouble(),
      maxTemp: (json['max_temp'] as num).toDouble(),
      avgHumidity: (json['avg_humidity'] as num).toDouble(),
      minHumidity: (json['min_humidity'] as num).toDouble(),
      maxHumidity: (json['max_humidity'] as num).toDouble(),
      avgVpd: (json['avg_vpd'] as num).toDouble(),
      minVpd: (json['min_vpd'] as num).toDouble(),
      maxVpd: (json['max_vpd'] as num).toDouble(),
      avgPh: json['avg_ph'] != null ? (json['avg_ph'] as num).toDouble() : null,
      avgEc: json['avg_ec'] != null ? (json['avg_ec'] as num).toDouble() : null,
      readingsCount: json['readings_count'] as int,
    );
  }
}
