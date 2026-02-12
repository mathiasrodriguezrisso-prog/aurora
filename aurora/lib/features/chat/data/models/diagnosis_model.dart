/// Modelo para el resultado de diagnóstico por imagen.
library;

import 'package:flutter/material.dart';

class DiagnosisModel {
  final String problem;
  final String severity; // 'low', 'moderate', 'severe', 'critical'
  final double confidence; // 0.0 a 1.0
  final String description;
  final List<String> causes;
  final List<String> solutions;
  final String estimatedRecovery;
  final String urgency; // 'low', 'medium', 'high', 'critical'

  const DiagnosisModel({
    required this.problem,
    required this.severity,
    required this.confidence,
    required this.description,
    required this.causes,
    required this.solutions,
    required this.estimatedRecovery,
    required this.urgency,
  });

  factory DiagnosisModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisModel(
      problem: json['problem'] as String? ?? 'Análisis no disponible',
      severity: json['severity'] as String? ?? 'low',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      causes: (json['causes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      solutions: (json['solutions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      estimatedRecovery: json['estimated_recovery'] as String? ?? 'Variable',
      urgency: json['urgency'] as String? ?? 'low',
    );
  }

  /// Para el caso donde el backend retorna diagnóstico como texto plano
  /// (sin el JSON estructurado), construir un DiagnosisModel básico
  factory DiagnosisModel.fromTextResponse(String responseText) {
    return DiagnosisModel(
      problem: 'Análisis Visual',
      severity: 'moderate',
      confidence: 0.7,
      description: responseText,
      causes: [],
      solutions: [],
      estimatedRecovery: 'Consulta a Dr. Aurora para más detalles',
      urgency: 'medium',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'problem': problem,
      'severity': severity,
      'confidence': confidence,
      'description': description,
      'causes': causes,
      'solutions': solutions,
      'estimated_recovery': estimatedRecovery,
      'urgency': urgency,
    };
  }
}

// Helpers para la UI
extension DiagnosisModelUI on DiagnosisModel {
  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'low': return const Color(0xFF4FC3F7);
      case 'moderate': return const Color(0xFFFFA726);
      case 'severe': return const Color(0xFFEF5350);
      case 'critical': return const Color(0xFFD32F2F);
      default: return const Color(0xFF9E9E9E);
    }
  }

  String get severityLabel {
    switch (severity.toLowerCase()) {
      case 'low': return 'Leve';
      case 'moderate': return 'Moderado';
      case 'severe': return 'Severo';
      case 'critical': return 'Crítico';
      default: return 'Desconocido';
    }
  }

  IconData get severityIcon {
    switch (severity.toLowerCase()) {
      case 'low': return Icons.info_outline;
      case 'moderate': return Icons.warning_amber;
      case 'severe': return Icons.error_outline;
      case 'critical': return Icons.dangerous;
      default: return Icons.help_outline;
    }
  }

  double get severityProgress {
    switch (severity.toLowerCase()) {
      case 'low': return 0.25;
      case 'moderate': return 0.5;
      case 'severe': return 0.75;
      case 'critical': return 1.0;
      default: return 0.0;
    }
  }
}
