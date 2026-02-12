/// Modelo de clima actual + ideales (Data Layer).
library;

import '../../domain/entities/climate_current_entity.dart';
import '../../domain/entities/climate_reading_entity.dart';
import 'climate_reading_model.dart';
class ClimateCurrentModel extends ClimateCurrentEntity {
  const ClimateCurrentModel({
    super.reading,
    required super.ideal,
    required super.phase,
    required super.week,
  });

  factory ClimateCurrentModel.fromJson(Map<String, dynamic> json) {
    return ClimateCurrentModel(
      reading: json['reading'] != null
          ? ClimateReadingModel.fromJson(json['reading'] as Map<String, dynamic>)
          : null,
      ideal: _IdealModel.fromJson(json['ideal'] as Map<String, dynamic>),
      phase: json['phase'] as String,
      week: json['week'] as int,
    );
  }
}

class _IdealModel extends ClimateIdealEntity {
  const _IdealModel({
    required super.tempMin,
    required super.tempMax,
    required super.humidityMin,
    required super.humidityMax,
    required super.vpdMin,
    required super.vpdMax,
    super.phMin,
    super.phMax,
    super.ecMin,
    super.ecMax,
  });

  factory _IdealModel.fromJson(Map<String, dynamic> json) {
    return _IdealModel(
      tempMin: (json['temp_min'] as num).toDouble(),
      tempMax: (json['temp_max'] as num).toDouble(),
      humidityMin: (json['humidity_min'] as num).toDouble(),
      humidityMax: (json['humidity_max'] as num).toDouble(),
      vpdMin: (json['vpd_min'] as num).toDouble(),
      vpdMax: (json['vpd_max'] as num).toDouble(),
      phMin: json['ph_min'] != null ? (json['ph_min'] as num).toDouble() : null,
      phMax: json['ph_max'] != null ? (json['ph_max'] as num).toDouble() : null,
      ecMin: json['ec_min'] != null ? (json['ec_min'] as num).toDouble() : null,
      ecMax: json['ec_max'] != null ? (json['ec_max'] as num).toDouble() : null,
    );
  }
}
