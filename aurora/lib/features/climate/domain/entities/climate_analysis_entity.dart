/// Entidad para el análisis de IA.
library;

class ClimateAlertEntity {
  final String parameter; // 'temperature', 'humidity', 'vpd', 'ph', 'ec'
  final String severity; // 'low', 'medium', 'high', 'critical'
  final String message;

  const ClimateAlertEntity({
    required this.parameter,
    required this.severity,
    required this.message,
  });
}

class ClimateAnalysisEntity {
  final int score;
  final String status; // 'excellent', 'good', 'fair', 'poor', 'critical'
  final String message; // consejo de la IA
  final List<ClimateAlertEntity> alerts;

  const ClimateAnalysisEntity({
    required this.score,
    required this.status,
    required this.message,
    required this.alerts,
  });
}
