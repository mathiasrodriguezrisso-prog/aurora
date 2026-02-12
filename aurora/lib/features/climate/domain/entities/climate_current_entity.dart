/// Entidad que combina la lectura actual + los ideales de la fase.
library;

import 'climate_reading_entity.dart';

class ClimateIdealEntity {
  final double tempMin;
  final double tempMax;
  final double humidityMin;
  final double humidityMax;
  final double vpdMin;
  final double vpdMax;
  final double? phMin;
  final double? phMax;
  final double? ecMin;
  final double? ecMax;

  const ClimateIdealEntity({
    required this.tempMin,
    required this.tempMax,
    required this.humidityMin,
    required this.humidityMax,
    required this.vpdMin,
    required this.vpdMax,
    this.phMin,
    this.phMax,
    this.ecMin,
    this.ecMax,
  });
}

class ClimateCurrentEntity {
  final ClimateReadingEntity? reading; // null si nunca ha registrado
  final ClimateIdealEntity ideal;
  final String phase;
  final int week;

  const ClimateCurrentEntity({
    this.reading,
    required this.ideal,
    required this.phase,
    required this.week,
  });
}
