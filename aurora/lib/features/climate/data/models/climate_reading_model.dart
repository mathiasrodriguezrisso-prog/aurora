/// Modelo de lectura climática (Data Layer).
library;

import '../../domain/entities/climate_reading_entity.dart';

class ClimateReadingModel extends ClimateReadingEntity {
  const ClimateReadingModel({
    required super.id,
    required super.growId,
    required super.temperature,
    required super.humidity,
    required super.vpd,
    super.ph,
    super.ec,
    super.watered,
    super.notes,
    required super.createdAt,
  });

  factory ClimateReadingModel.fromJson(Map<String, dynamic> json) {
    return ClimateReadingModel(
      id: json['id'] as String,
      growId: json['grow_id'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      vpd: (json['vpd'] as num).toDouble(),
      ph: json['ph'] != null ? (json['ph'] as num).toDouble() : null,
      ec: json['ec'] != null ? (json['ec'] as num).toDouble() : null,
      watered: json['watered'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grow_id': growId,
      'temperature': temperature,
      'humidity': humidity,
      'vpd': vpd,
      'ph': ph,
      'ec': ec,
      'watered': watered,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
