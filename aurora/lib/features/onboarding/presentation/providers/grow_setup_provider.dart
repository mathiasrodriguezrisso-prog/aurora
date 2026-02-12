/// Provider del wizard de configuración de cultivo.
/// Sigue el patrón de StateNotifier + StateNotifierProvider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../grow/presentation/providers/grow_providers.dart';
import '../../../grow/domain/usecases/generate_grow_plan.dart';
import '../../data/models/grow_setup_data.dart';

// ─────────────────────────────────────────────────────
// Estado del wizard
// ─────────────────────────────────────────────────────

class GrowSetupState {
  final GrowSetupData data;
  final int currentStep;
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  const GrowSetupState({
    this.data = const GrowSetupData(),
    this.currentStep = 0,
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  GrowSetupState copyWith({
    GrowSetupData? data,
    int? currentStep,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GrowSetupState(
      data: data ?? this.data,
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// Retorna true si el paso actual tiene datos mínimos.
  bool get canAdvance => data.isStepComplete(currentStep);
}

// ─────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────

class GrowSetupNotifier extends StateNotifier<GrowSetupState> {
  final GenerateGrowPlan _generateGrowPlan;

  GrowSetupNotifier(this._generateGrowPlan) : super(const GrowSetupState());

  // ── Paso 0: Nivel de experiencia ──
  void setExperienceLevel(String level) {
    state = state.copyWith(
      data: state.data.copyWith(experienceLevel: level),
      clearError: true,
    );
  }

  // ── Paso 1: Tipo de cultivo ──
  void setGrowType(String type) {
    state = state.copyWith(
      data: state.data.copyWith(growType: type),
      clearError: true,
    );
  }

  // ── Paso 2: Medio ──
  void setMedium(String medium) {
    state = state.copyWith(
      data: state.data.copyWith(medium: medium),
      clearError: true,
    );
  }

  // ── Paso 3: Espacio y equipamiento ──
  void setSpaceSize(double size) {
    state = state.copyWith(
      data: state.data.copyWith(spaceSizeM2: size),
    );
  }

  void setLightType(String type) {
    state = state.copyWith(
      data: state.data.copyWith(
        lightType: type,
        clearLightWattage: type == 'sun',
      ),
      clearError: true,
    );
  }

  void setLightWattage(int? wattage) {
    state = state.copyWith(
      data: state.data.copyWith(lightWattage: wattage),
    );
  }

  void setHasExtractor(bool value) {
    state = state.copyWith(
      data: state.data.copyWith(hasExtractor: value),
    );
  }

  void setHasFan(bool value) {
    state = state.copyWith(
      data: state.data.copyWith(hasFan: value),
    );
  }

  void setHasCarbonFilter(bool value) {
    state = state.copyWith(
      data: state.data.copyWith(hasCarbonFilter: value),
    );
  }

  // ── Paso 4: Cepa y semilla ──
  void setStrain(String strain) {
    state = state.copyWith(
      data: state.data.copyWith(strain: strain),
      clearError: true,
    );
  }

  void setSeedType(String type) {
    state = state.copyWith(
      data: state.data.copyWith(seedType: type),
      clearError: true,
    );
  }

  void setStartDate(DateTime date) {
    state = state.copyWith(
      data: state.data.copyWith(startDate: date),
    );
  }

  // ── Navegación del wizard ──

  /// Avanzar al siguiente paso (solo si el actual es válido).
  void nextStep() {
    if (!state.canAdvance) return;
    if (state.currentStep >= 4) return;
    state = state.copyWith(
      currentStep: state.currentStep + 1,
      clearError: true,
    );
  }

  /// Retroceder sin validar.
  void previousStep() {
    if (state.currentStep <= 0) return;
    state = state.copyWith(
      currentStep: state.currentStep - 1,
      clearError: true,
    );
  }

  // ── Enviar al backend ──

  /// Genera el plan de cultivo usando el repositorio de Grow.
  Future<void> submitGrowSetup() async {
    if (!state.canAdvance) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _generateGrowPlan(state.data.toApiJson());

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (plan) => state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────

final growSetupProvider =
    StateNotifierProvider<GrowSetupNotifier, GrowSetupState>((ref) {
  final useCase = ref.watch(generateGrowPlanProvider);
  return GrowSetupNotifier(useCase);
});
