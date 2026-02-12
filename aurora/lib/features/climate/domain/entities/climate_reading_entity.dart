/// Entidad inmutable de una lectura climática.
library;

class ClimateReadingEntity {
  final String id;
  final String growId;
  final double temperature;
  final double humidity;
  final double vpd;
  final double? ph;
  final double? ec;
  final bool watered;
  final String? notes;
  final DateTime createdAt;

  const ClimateReadingEntity({
    required this.id,
    required this.growId,
    required this.temperature,
    required this.humidity,
    required this.vpd,
    this.ph,
    this.ec,
    this.watered = false,
    this.notes,
    required this.createdAt,
  });
}
