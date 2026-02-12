/// Modelo de análisis IA (Data Layer).
library;

import '../../domain/entities/climate_analysis_entity.dart';

class ClimateAnalysisModel extends ClimateAnalysisEntity {
  const ClimateAnalysisModel({
    required super.score,
    required super.status,
    required super.message,
    required super.alerts,
  });

  factory ClimateAnalysisModel.fromJson(Map<String, dynamic> json) {
    return ClimateAnalysisModel(
      score: json['score'] as int,
      status: json['status'] as String,
      message: json['message'] as String,
      alerts: (json['alerts'] as List)
          .map((e) => _AlertModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class _AlertModel extends ClimateAlertEntity {
  const _AlertModel({
    required super.parameter,
    required super.severity,
    required super.message,
  });

  factory _AlertModel.fromJson(Map<String, dynamic> json) {
    return _AlertModel(
      parameter: json['parameter'] as String,
      severity: json['severity'] as String,
      message: json['message'] as String,
    );
  }
}
