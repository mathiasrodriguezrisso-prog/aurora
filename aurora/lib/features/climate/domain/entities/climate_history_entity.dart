/// Entidad para el historial con stats.
library;

import 'climate_reading_entity.dart';

class ClimateStatsEntity {
  final double avgTemp;
  final double minTemp;
  final double maxTemp;
  final double avgHumidity;
  final double minHumidity;
  final double maxHumidity;
  final double avgVpd;
  final double minVpd;
  final double maxVpd;
  final double? avgPh;
  final double? avgEc;
  final int readingsCount;

  const ClimateStatsEntity({
    required this.avgTemp,
    required this.minTemp,
    required this.maxTemp,
    required this.avgHumidity,
    required this.minHumidity,
    required this.maxHumidity,
    required this.avgVpd,
    required this.minVpd,
    required this.maxVpd,
    this.avgPh,
    this.avgEc,
    required this.readingsCount,
  });
}

class ClimateHistoryEntity {
  final List<ClimateReadingEntity> readings;
  final ClimateStatsEntity stats;

  const ClimateHistoryEntity({
    required this.readings,
    required this.stats,
  });
}
