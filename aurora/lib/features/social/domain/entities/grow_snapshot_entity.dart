/// Entidad inmutable para snapshot de cultivo vinculado a un post.
library;

class GrowSnapshotEntity {
  final String strain;
  final String phase;
  final int week;
  final double temperature;
  final double humidity;
  final double vpd;
  final String medium;
  final String lightType;

  const GrowSnapshotEntity({
    required this.strain,
    required this.phase,
    required this.week,
    required this.temperature,
    required this.humidity,
    required this.vpd,
    required this.medium,
    required this.lightType,
  });
}
