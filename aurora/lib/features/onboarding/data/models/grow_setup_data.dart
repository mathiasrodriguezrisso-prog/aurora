/// DTO inmutable para los datos del wizard de cultivo.
/// Contiene todos los campos recopilados paso a paso.
/// toApiJson() genera el cuerpo exacto para POST /api/v1/grow/generate-plan.
library;

import 'dart:math';

class GrowSetupData {
  final String? experienceLevel;
  final String? growType;
  final String? medium;
  final double spaceSizeM2;
  final String? lightType;
  final int? lightWattage;
  final bool hasExtractor;
  final bool hasFan;
  final bool hasCarbonFilter;
  final String? strain;
  final String? seedType;
  final DateTime? startDate;

  const GrowSetupData({
    this.experienceLevel,
    this.growType,
    this.medium,
    this.spaceSizeM2 = 1.0,
    this.lightType,
    this.lightWattage,
    this.hasExtractor = false,
    this.hasFan = false,
    this.hasCarbonFilter = false,
    this.strain,
    this.seedType,
    this.startDate,
  });

  GrowSetupData copyWith({
    String? experienceLevel,
    String? growType,
    String? medium,
    double? spaceSizeM2,
    String? lightType,
    int? lightWattage,
    bool? hasExtractor,
    bool? hasFan,
    bool? hasCarbonFilter,
    String? strain,
    String? seedType,
    DateTime? startDate,
    bool clearLightWattage = false,
  }) {
    return GrowSetupData(
      experienceLevel: experienceLevel ?? this.experienceLevel,
      growType: growType ?? this.growType,
      medium: medium ?? this.medium,
      spaceSizeM2: spaceSizeM2 ?? this.spaceSizeM2,
      lightType: lightType ?? this.lightType,
      lightWattage: clearLightWattage ? null : (lightWattage ?? this.lightWattage),
      hasExtractor: hasExtractor ?? this.hasExtractor,
      hasFan: hasFan ?? this.hasFan,
      hasCarbonFilter: hasCarbonFilter ?? this.hasCarbonFilter,
      strain: strain ?? this.strain,
      seedType: seedType ?? this.seedType,
      startDate: startDate ?? this.startDate,
    );
  }

  /// Genera el JSON para POST /api/v1/grow/generate-plan.
  Map<String, dynamic> toApiJson() {
    final effectiveStart = startDate ?? DateTime.now();
    
    // Calcular dimensiones aproximadas basadas en m2 (asumiendo cuadrado)
    // m2 = (side/100) * (side/100) -> side = sqrt(m2) * 100
    final sideCm = (matchSpaceSizeToSideCm(spaceSizeM2)).round();
    
    return {
      'strain_name': strain ?? 'Unknown Strain',
      'seed_type': seedType?.toLowerCase() ?? 'feminized',
      'medium': medium?.toLowerCase() ?? 'soil',
      'light_type': lightType ?? 'LED',
      'light_wattage': lightType == 'sun' ? 600 : (lightWattage ?? 300), // Default 600W equivalent for sun
      'space_width_cm': sideCm,
      'space_length_cm': sideCm,
      'space_height_cm': 200, // Alto estándar por defecto
      'start_date': "${effectiveStart.year}-${effectiveStart.month.toString().padLeft(2, '0')}-${effectiveStart.day.toString().padLeft(2, '0')}", // YYYY-MM-DD
      'experience_level': _mapExperienceLevel(experienceLevel),
    };
  }

  String _mapExperienceLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'novice':
        return 'beginner';
      case 'intermediate':
        return 'intermediate';
      case 'expert':
        return 'advanced';
      default:
        return 'beginner';
    }
  }

  double matchSpaceSizeToSideCm(double m2) {
    // sqrt(area) * 100 to get cm side of a square
    return sqrt(m2) * 100;
  }

  /// Valida si un paso específico tiene los datos mínimos.
  bool isStepComplete(int step) {
    switch (step) {
      case 0:
        return experienceLevel != null;
      case 1:
        return growType != null;
      case 2:
        return medium != null;
      case 3:
        return lightType != null;
      case 4:
        return strain != null && seedType != null;
      default:
        return false;
    }
  }
}
