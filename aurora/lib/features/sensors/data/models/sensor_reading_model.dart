/// 📁 lib/features/sensors/data/models/sensor_reading_model.dart
/// Data model for individual sensor readings.
library;

class SensorReadingModel {
  final String id;
  final String growId;
  final double? temperature;
  final double? humidity;
  final double? ph;
  final double? ec;
  final double? co2;
  final double? lightPpfd;
  final DateTime createdAt;

  const SensorReadingModel({
    required this.id,
    required this.growId,
    this.temperature,
    this.humidity,
    this.ph,
    this.ec,
    this.co2,
    this.lightPpfd,
    required this.createdAt,
  });

  factory SensorReadingModel.fromJson(Map<String, dynamic> json) {
    return SensorReadingModel(
      id: json['id'] as String? ?? '',
      growId: json['grow_id'] as String? ?? '',
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      ph: (json['ph'] as num?)?.toDouble(),
      ec: (json['ec'] as num?)?.toDouble(),
      co2: (json['co2'] as num?)?.toDouble(),
      lightPpfd: (json['light_ppfd'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'grow_id': growId,
        if (temperature != null) 'temperature': temperature,
        if (humidity != null) 'humidity': humidity,
        if (ph != null) 'ph': ph,
        if (ec != null) 'ec': ec,
        if (co2 != null) 'co2': co2,
        if (lightPpfd != null) 'light_ppfd': lightPpfd,
        'created_at': createdAt.toIso8601String(),
      };

  /// Compute VPD from temperature and humidity using Tetens formula.
  double? get vpd {
    if (temperature == null || humidity == null) return null;
    final t = temperature!;
    final h = humidity!;
    // Saturation vapor pressure (kPa)
    final svp = 0.6108 * _exp((17.27 * t) / (t + 237.3));
    return svp * (1 - h / 100);
  }

  static double _exp(double x) {
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 20; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }
}
