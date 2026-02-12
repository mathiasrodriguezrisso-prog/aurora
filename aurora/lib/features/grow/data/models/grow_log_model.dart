/// Modelo de datos para registro diario del cultivo.
library;

class GrowLogModel {
  final String id;
  final String growId;
  final DateTime date;
  final double temperature;
  final double humidity;
  final double? ph;
  final double? ec;
  final double vpd;
  final bool watered;
  final String? nutrientsApplied;
  final String? notes;
  final String? photoUrl;

  const GrowLogModel({
    required this.id,
    required this.growId,
    required this.date,
    required this.temperature,
    required this.humidity,
    this.ph,
    this.ec,
    required this.vpd,
    required this.watered,
    this.nutrientsApplied,
    this.notes,
    this.photoUrl,
  });

  factory GrowLogModel.fromJson(Map<String, dynamic> json) {
    return GrowLogModel(
      id: json['id'] as String? ?? '',
      growId: json['grow_id'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      temperature: (json['temperature'] as num?)?.toDouble() ?? 25.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 60.0,
      ph: (json['ph'] as num?)?.toDouble(),
      ec: (json['ec'] as num?)?.toDouble(),
      vpd: (json['vpd'] as num?)?.toDouble() ?? 1.0,
      watered: json['watered'] as bool? ?? false,
      nutrientsApplied: json['nutrients_applied'] as String?,
      notes: json['notes'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'grow_id': growId,
      'date': date.toIso8601String().split('T')[0],
      'temperature': temperature,
      'humidity': humidity,
      'ph': ph,
      'ec': ec,
      'vpd': vpd,
      'watered': watered,
      'nutrients_applied': nutrientsApplied,
      'notes': notes,
      'photo_url': photoUrl,
    };
  }
}
