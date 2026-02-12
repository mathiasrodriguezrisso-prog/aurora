
import 'dart:math';

class SensorReadingModel {
  final String id;
  final String growId;
  final double? temperature; // Celsius
  final double? humidity;    // Percent
  final double? ph;
  final double? ec;          // mS/cm
  final DateTime createdAt;

  SensorReadingModel({
    required this.id,
    required this.growId,
    this.temperature,
    this.humidity,
    this.ph,
    this.ec,
    required this.createdAt,
  });

  // Calculate VPD (Vapor Pressure Deficit) in kPa
  double? get vpd {
    if (temperature == null || humidity == null) return null;
    
    // Saturation Vapor Pressure (Tetens formula)
    final svp = 0.6108 * exp((17.27 * temperature!) / (temperature! + 237.3));
    
    // Actual Vapor Pressure is implied by humidity
    // VPD = SVP * (1 - RH/100)
    final vpdValue = svp * (1 - humidity! / 100.0);
    
    // Return rounded to 2 decimal places
    return double.parse(vpdValue.toStringAsFixed(2));
  }

  factory SensorReadingModel.fromJson(Map<String, dynamic> json) {
    return SensorReadingModel(
      id: json['id'] as String,
      growId: json['grow_id'] as String,
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      ph: (json['ph'] as num?)?.toDouble(),
      ec: (json['ec'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grow_id': growId,
      'temperature': temperature,
      'humidity': humidity,
      'ph': ph,
      'ec': ec,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
