/// Modelo de GrowSnapshot para la capa de datos.
library;

import '../../domain/entities/grow_snapshot_entity.dart';

class GrowSnapshotModel extends GrowSnapshotEntity {
  const GrowSnapshotModel({
    required super.strain,
    required super.phase,
    required super.week,
    required super.temperature,
    required super.humidity,
    required super.vpd,
    required super.medium,
    required super.lightType,
  });

  factory GrowSnapshotModel.fromJson(Map<String, dynamic> json) {
    return GrowSnapshotModel(
      strain: json['strain'] as String? ?? '',
      phase: json['phase'] as String? ?? '',
      week: json['week'] as int? ?? 0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0,
      vpd: (json['vpd'] as num?)?.toDouble() ?? 0,
      medium: json['medium'] as String? ?? '',
      lightType: json['light_type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'strain': strain,
      'phase': phase,
      'week': week,
      'temperature': temperature,
      'humidity': humidity,
      'vpd': vpd,
      'medium': medium,
      'light_type': lightType,
    };
  }
}
