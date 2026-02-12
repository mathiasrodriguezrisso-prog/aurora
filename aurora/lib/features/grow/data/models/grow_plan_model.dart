/// Modelo de datos para un plan de cultivo.
/// Mapea el JSON del backend y extiende la lógica de GrowPlanEntity.
library;

import '../../domain/entities/grow_plan_entity.dart';

/// Modelo completo del grow con estado actual.
/// Envuelve GrowPlanEntity y agrega campos de estado del backend.
class GrowPlanModel {
  final String id;
  final String userId;
  final String strain;
  final String medium;
  final String lighting;
  final DateTime startDate;
  final int estimatedTotalWeeks;
  final String currentPhase;
  final int currentWeek;
  final String status;
  final GrowPlanEntity? plan;
  final List<GrowPlanPhase> phases;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GrowPlanModel({
    required this.id,
    required this.userId,
    required this.strain,
    required this.medium,
    required this.lighting,
    required this.startDate,
    required this.estimatedTotalWeeks,
    required this.currentPhase,
    required this.currentWeek,
    required this.status,
    this.plan,
    this.phases = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory GrowPlanModel.fromJson(Map<String, dynamic> json) {
    return GrowPlanModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      strain: json['strain'] as String? ?? json['strain_name'] as String? ?? '',
      medium: json['medium'] as String? ?? '',
      lighting: json['lighting'] as String? ?? json['light_type'] as String? ?? '',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : DateTime.now(),
      estimatedTotalWeeks: json['estimated_total_weeks'] as int? ?? 12,
      currentPhase: json['current_phase'] as String? ?? 'germination',
      currentWeek: json['current_week'] as int? ?? 1,
      status: json['status'] as String? ?? 'active',
      plan: json['plan'] != null
          ? GrowPlanEntity.fromJson(json['plan'] as Map<String, dynamic>)
          : null,
      phases: (json['phases'] as List<dynamic>?)
              ?.map((p) => GrowPlanPhase.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'strain': strain,
      'medium': medium,
      'lighting': lighting,
      'start_date': startDate.toIso8601String().split('T')[0],
      'estimated_total_weeks': estimatedTotalWeeks,
      'current_phase': currentPhase,
      'current_week': currentWeek,
      'status': status,
    };
  }

  /// Días transcurridos desde el inicio del cultivo.
  int get daysElapsed => DateTime.now().difference(startDate).inDays;

  /// Progreso general como porcentaje 0.0 – 1.0.
  double get progress {
    final totalDays = estimatedTotalWeeks * 7;
    if (totalDays == 0) return 0.0;
    return (daysElapsed / totalDays).clamp(0.0, 1.0);
  }

  /// Si el cultivo está activo.
  bool get isActive => status == 'active';

  GrowPlanModel copyWith({
    String? id,
    String? userId,
    String? strain,
    String? medium,
    String? lighting,
    DateTime? startDate,
    int? estimatedTotalWeeks,
    String? currentPhase,
    int? currentWeek,
    String? status,
    GrowPlanEntity? plan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GrowPlanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      strain: strain ?? this.strain,
      medium: medium ?? this.medium,
      lighting: lighting ?? this.lighting,
      startDate: startDate ?? this.startDate,
      estimatedTotalWeeks: estimatedTotalWeeks ?? this.estimatedTotalWeeks,
      currentPhase: currentPhase ?? this.currentPhase,
      currentWeek: currentWeek ?? this.currentWeek,
      status: status ?? this.status,
      plan: plan ?? this.plan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
