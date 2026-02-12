/// Grow Plan Entity
/// Domain model for AI-generated grow plans.
library;

import 'package:flutter/foundation.dart';

/// Environment parameters for a growth phase.
@immutable
class EnvironmentParams {
  final int temperatureDayC;
  final int temperatureNightC;
  final int humidityPercent;
  final double vpdMin;
  final double vpdMax;
  final int lightHours;
  final int? co2Ppm;

  const EnvironmentParams({
    required this.temperatureDayC,
    required this.temperatureNightC,
    required this.humidityPercent,
    required this.vpdMin,
    required this.vpdMax,
    required this.lightHours,
    this.co2Ppm,
  });

  factory EnvironmentParams.fromJson(Map<String, dynamic> json) {
    return EnvironmentParams(
      temperatureDayC: json['temperature_day_c'] as int? ?? 25,
      temperatureNightC: json['temperature_night_c'] as int? ?? 20,
      humidityPercent: json['humidity_percent'] as int? ?? 60,
      vpdMin: (json['vpd_min'] as num?)?.toDouble() ?? 0.8,
      vpdMax: (json['vpd_max'] as num?)?.toDouble() ?? 1.2,
      lightHours: json['light_hours'] as int? ?? 18,
      co2Ppm: json['co2_ppm'] as int?,
    );
  }
}

/// Nutrient schedule for a growth phase.
@immutable
class NutrientSchedule {
  final String nitrogenLevel;
  final String phosphorusLevel;
  final String potassiumLevel;
  final double ecMin;
  final double ecMax;
  final double phMin;
  final double phMax;
  final String feedingFrequency;
  final List<String> additives;

  const NutrientSchedule({
    required this.nitrogenLevel,
    required this.phosphorusLevel,
    required this.potassiumLevel,
    required this.ecMin,
    required this.ecMax,
    required this.phMin,
    required this.phMax,
    required this.feedingFrequency,
    required this.additives,
  });

  factory NutrientSchedule.fromJson(Map<String, dynamic> json) {
    return NutrientSchedule(
      nitrogenLevel: json['nitrogen_level'] as String? ?? 'medium',
      phosphorusLevel: json['phosphorus_level'] as String? ?? 'medium',
      potassiumLevel: json['potassium_level'] as String? ?? 'medium',
      ecMin: (json['ec_min'] as num?)?.toDouble() ?? 1.0,
      ecMax: (json['ec_max'] as num?)?.toDouble() ?? 1.5,
      phMin: (json['ph_min'] as num?)?.toDouble() ?? 6.0,
      phMax: (json['ph_max'] as num?)?.toDouble() ?? 6.5,
      feedingFrequency: json['feeding_frequency'] as String? ?? 'Every 2-3 days',
      additives: (json['additives'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

/// A task within a week.
@immutable
class WeeklyTask {
  final int day;
  final String taskType;
  final String title;
  final String description;
  final bool isCritical;

  const WeeklyTask({
    required this.day,
    required this.taskType,
    required this.title,
    required this.description,
    required this.isCritical,
  });

  factory WeeklyTask.fromJson(Map<String, dynamic> json) {
    return WeeklyTask(
      day: json['day'] as int? ?? 1,
      taskType: json['task_type'] as String? ?? 'note',
      title: json['title'] as String? ?? 'Task',
      description: json['description'] as String? ?? '',
      isCritical: json['is_critical'] as bool? ?? false,
    );
  }
}

/// A week within a growth phase.
@immutable
class PhaseWeek {
  final int weekNumber;
  final String focus;
  final List<WeeklyTask> tasks;
  final List<String> tips;

  const PhaseWeek({
    required this.weekNumber,
    required this.focus,
    required this.tasks,
    required this.tips,
  });

  factory PhaseWeek.fromJson(Map<String, dynamic> json) {
    return PhaseWeek(
      weekNumber: json['week_number'] as int? ?? 1,
      focus: json['focus'] as String? ?? '',
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((t) => WeeklyTask.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      tips: (json['tips'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

/// A complete phase in the grow plan.
@immutable
class GrowPlanPhase {
  final String phase;
  final String name;
  final int durationDays;
  final int startDay;
  final int endDay;
  final String description;
  final EnvironmentParams environment;
  final NutrientSchedule nutrients;
  final List<PhaseWeek> weeks;
  final List<String> keyMilestones;
  final List<String> commonIssues;

  const GrowPlanPhase({
    required this.phase,
    required this.name,
    required this.durationDays,
    required this.startDay,
    required this.endDay,
    required this.description,
    required this.environment,
    required this.nutrients,
    required this.weeks,
    required this.keyMilestones,
    required this.commonIssues,
  });

  factory GrowPlanPhase.fromJson(Map<String, dynamic> json) {
    return GrowPlanPhase(
      phase: json['phase'] as String? ?? 'vegetative',
      name: json['name'] as String? ?? 'Phase',
      durationDays: json['duration_days'] as int? ?? 14,
      startDay: json['start_day'] as int? ?? 1,
      endDay: json['end_day'] as int? ?? 14,
      description: json['description'] as String? ?? '',
      environment: EnvironmentParams.fromJson(
          json['environment'] as Map<String, dynamic>? ?? {}),
      nutrients: NutrientSchedule.fromJson(
          json['nutrients'] as Map<String, dynamic>? ?? {}),
      weeks: (json['weeks'] as List<dynamic>?)
              ?.map((w) => PhaseWeek.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      keyMilestones:
          (json['key_milestones'] as List<dynamic>?)?.cast<String>() ?? [],
      commonIssues:
          (json['common_issues'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

/// Summary of the grow plan.
@immutable
class GrowPlanSummary {
  final int totalDurationDays;
  final int estimatedYieldMin;
  final int estimatedYieldMax;
  final int difficultyRating;
  final List<String> keySuccessFactors;
  final List<String> strainSpecificTips;

  const GrowPlanSummary({
    required this.totalDurationDays,
    required this.estimatedYieldMin,
    required this.estimatedYieldMax,
    required this.difficultyRating,
    required this.keySuccessFactors,
    required this.strainSpecificTips,
  });

  factory GrowPlanSummary.fromJson(Map<String, dynamic> json) {
    return GrowPlanSummary(
      totalDurationDays: json['total_duration_days'] as int? ?? 120,
      estimatedYieldMin: json['estimated_yield_grams_min'] as int? ?? 50,
      estimatedYieldMax: json['estimated_yield_grams_max'] as int? ?? 150,
      difficultyRating: json['difficulty_rating'] as int? ?? 3,
      keySuccessFactors:
          (json['key_success_factors'] as List<dynamic>?)?.cast<String>() ?? [],
      strainSpecificTips:
          (json['strain_specific_tips'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

/// Complete grow plan entity.
@immutable
class GrowPlanEntity {
  final String? id;
  final String strainName;
  final String seedType;
  final String medium;
  final DateTime startDate;
  final GrowPlanSummary summary;
  final List<GrowPlanPhase> phases;
  final String generatedAt;

  const GrowPlanEntity({
    this.id,
    required this.strainName,
    required this.seedType,
    required this.medium,
    required this.startDate,
    required this.summary,
    required this.phases,
    required this.generatedAt,
  });

  factory GrowPlanEntity.fromJson(Map<String, dynamic> json) {
    return GrowPlanEntity(
      id: json['id'] as String?,
      strainName: json['strain_name'] as String? ?? '',
      seedType: json['seed_type'] as String? ?? 'feminized',
      medium: json['medium'] as String? ?? 'soil',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : DateTime.now(),
      summary: GrowPlanSummary.fromJson(
          json['summary'] as Map<String, dynamic>? ?? {}),
      phases: (json['phases'] as List<dynamic>?)
              ?.map((p) => GrowPlanPhase.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      generatedAt: json['generated_at'] as String? ?? '',
    );
  }

  /// Get current phase based on days elapsed.
  GrowPlanPhase? getCurrentPhase(int daysElapsed) {
    for (final phase in phases) {
      if (daysElapsed >= phase.startDay && daysElapsed <= phase.endDay) {
        return phase;
      }
    }
    return phases.isNotEmpty ? phases.last : null;
  }

  /// Get progress percentage.
  double getProgress(int daysElapsed) {
    if (summary.totalDurationDays == 0) return 0;
    return (daysElapsed / summary.totalDurationDays).clamp(0.0, 1.0);
  }
}

/// Request model for generating a grow plan.
@immutable
class GrowPlanRequest {
  final String strainName;
  final String seedType;
  final String medium;
  final String lightType;
  final int lightWattage;
  final int spaceWidthCm;
  final int spaceLengthCm;
  final int spaceHeightCm;
  final DateTime startDate;
  final String experienceLevel;

  const GrowPlanRequest({
    required this.strainName,
    this.seedType = 'feminized',
    this.medium = 'soil',
    this.lightType = 'LED',
    this.lightWattage = 300,
    this.spaceWidthCm = 60,
    this.spaceLengthCm = 60,
    this.spaceHeightCm = 150,
    required this.startDate,
    this.experienceLevel = 'beginner',
  });

  Map<String, dynamic> toJson() {
    return {
      'strain_name': strainName,
      'seed_type': seedType,
      'medium': medium,
      'light_type': lightType,
      'light_wattage': lightWattage,
      'space_width_cm': spaceWidthCm,
      'space_length_cm': spaceLengthCm,
      'space_height_cm': spaceHeightCm,
      'start_date': startDate.toIso8601String().split('T')[0],
      'experience_level': experienceLevel,
    };
  }
}
