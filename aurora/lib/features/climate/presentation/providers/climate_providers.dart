/// Providers de Riverpod para el módulo Climate.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/vpd_calculator.dart';
import '../../data/datasources/climate_remote_datasource.dart';
import '../../data/repositories/climate_repository_impl.dart';
import '../../domain/entities/climate_analysis_entity.dart';
import '../../domain/entities/climate_current_entity.dart';
import '../../domain/entities/climate_history_entity.dart';
import '../../domain/entities/climate_reading_entity.dart';
import '../../domain/repositories/climate_repository.dart';
import '../../domain/usecases/add_climate_reading.dart';
import '../../domain/usecases/get_climate_analysis.dart';
import '../../domain/usecases/get_climate_history.dart';
import '../../domain/usecases/get_current_climate.dart';

// ─────────────────────────────────────────────────────
// Infrastructure Providers
// ─────────────────────────────────────────────────────

final climateRemoteDataSourceProvider = Provider<ClimateRemoteDataSource>((ref) {
  return ClimateRemoteDataSource(ref.watch(apiClientProvider));
});

final climateRepositoryProvider = Provider<ClimateRepository>((ref) {
  return ClimateRepositoryImpl(ref.watch(climateRemoteDataSourceProvider));
});

// ─────────────────────────────────────────────────────
// UseCase Providers
// ─────────────────────────────────────────────────────

final addClimateReadingUseCaseProvider = Provider<AddClimateReading>((ref) {
  return AddClimateReading(ref.watch(climateRepositoryProvider));
});

final getCurrentClimateUseCaseProvider = Provider<GetCurrentClimate>((ref) {
  return GetCurrentClimate(ref.watch(climateRepositoryProvider));
});

final getClimateHistoryUseCaseProvider = Provider<GetClimateHistory>((ref) {
  return GetClimateHistory(ref.watch(climateRepositoryProvider));
});

final getClimateAnalysisUseCaseProvider = Provider<GetClimateAnalysis>((ref) {
  return GetClimateAnalysis(ref.watch(climateRepositoryProvider));
});

// ─────────────────────────────────────────────────────
// Climate Current State & Notifier
// ─────────────────────────────────────────────────────

class ClimateCurrentState {
  final ClimateCurrentEntity? current; // null = nunca ha registrado
  final bool isLoading;
  final String? errorMessage;
  final int environmentScore;
  final VPDZone vpdZone;

  const ClimateCurrentState({
    this.current,
    this.isLoading = false,
    this.errorMessage,
    this.environmentScore = 0,
    this.vpdZone = VPDZone.optimal,
  });

  ClimateCurrentState copyWith({
    ClimateCurrentEntity? current,
    bool? isLoading,
    String? errorMessage,
    int? environmentScore,
    VPDZone? vpdZone,
  }) {
    return ClimateCurrentState(
      current: current ?? this.current,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Reset error if not provided
      environmentScore: environmentScore ?? this.environmentScore,
      vpdZone: vpdZone ?? this.vpdZone,
    );
  }
}

class ClimateCurrentNotifier extends StateNotifier<ClimateCurrentState> {
  final GetCurrentClimate _getCurrent;
  final AddClimateReading _addReading;

  ClimateCurrentNotifier(this._getCurrent, this._addReading)
      : super(const ClimateCurrentState());

  Future<void> loadCurrent(String growId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _getCurrent.call(growId);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (data) {
        // Calcular score y zona localmente
        int score = 0;
        VPDZone zone = VPDZone.optimal;

        if (data.reading != null) {
          final r = data.reading!;
          final i = data.ideal;

          score = VPDCalculator.calculateEnvironmentScore(
            temp: r.temperature,
            targetTempMin: i.tempMin,
            targetTempMax: i.tempMax,
            humidity: r.humidity,
            targetHumMin: i.humidityMin,
            targetHumMax: i.humidityMax,
            vpd: r.vpd,
            phase: data.phase,
            ph: r.ph,
            targetPhMin: i.phMin,
            targetPhMax: i.phMax,
            ec: r.ec,
            targetEcMin: i.ecMin,
            targetEcMax: i.ecMax,
          );
          zone = VPDCalculator.getVPDZone(r.vpd, data.phase);
        }

        state = state.copyWith(
          isLoading: false,
          current: data,
          environmentScore: score,
          vpdZone: zone,
        );
      },
    );
  }

  Future<bool> addReading({
    required String growId,
    required double temperature,
    required double humidity,
    double? ph,
    double? ec,
    bool watered = false,
    String? notes,
  }) async {
    // No ponemos isLoading global porque suele ser una operación modal
    final result = await _addReading.call(
      growId: growId,
      temperature: temperature,
      humidity: humidity,
      ph: ph,
      ec: ec,
      watered: watered,
      notes: notes,
    );

    return result.fold(
      (failure) {
        // Podríamos setear errorMessage en state, pero para formularios
        // es mejor retornar false y que la UI muestre SnackBar.
        return false;
      },
      (reading) {
        // Recargar current para actualizar la UI con los nuevos datos
        loadCurrent(growId);
        return true;
      },
    );
  }
}

final climateCurrentProvider =
    StateNotifierProvider<ClimateCurrentNotifier, ClimateCurrentState>((ref) {
  return ClimateCurrentNotifier(
    ref.watch(getCurrentClimateUseCaseProvider),
    ref.watch(addClimateReadingUseCaseProvider),
  );
});

// ─────────────────────────────────────────────────────
// Climate History State & Notifier
// ─────────────────────────────────────────────────────

class ClimateHistoryState {
  final ClimateHistoryEntity? history;
  final int selectedDays; // 1, 7, 30
  final bool isLoading;
  final String? errorMessage;

  const ClimateHistoryState({
    this.history,
    this.selectedDays = 7,
    this.isLoading = false,
    this.errorMessage,
  });

  ClimateHistoryState copyWith({
    ClimateHistoryEntity? history,
    int? selectedDays,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ClimateHistoryState(
      history: history ?? this.history,
      selectedDays: selectedDays ?? this.selectedDays,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ClimateHistoryNotifier extends StateNotifier<ClimateHistoryState> {
  final GetClimateHistory _getHistory;

  ClimateHistoryNotifier(this._getHistory) : super(const ClimateHistoryState());

  Future<void> loadHistory(String growId, {int days = 7}) async {
    state = state.copyWith(
      isLoading: true,
      selectedDays: days,
      errorMessage: null,
    );
    final result = await _getHistory.call(growId, days: days);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (data) => state = state.copyWith(
        isLoading: false,
        history: data,
      ),
    );
  }
}

final climateHistoryProvider =
    StateNotifierProvider<ClimateHistoryNotifier, ClimateHistoryState>((ref) {
  return ClimateHistoryNotifier(ref.watch(getClimateHistoryUseCaseProvider));
});

// ─────────────────────────────────────────────────────
// Climate Analysis State & Notifier
// ─────────────────────────────────────────────────────

class ClimateAnalysisState {
  final ClimateAnalysisEntity? analysis;
  final bool isLoading;
  final String? errorMessage;

  const ClimateAnalysisState({
    this.analysis,
    this.isLoading = false,
    this.errorMessage,
  });

  ClimateAnalysisState copyWith({
    ClimateAnalysisEntity? analysis,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ClimateAnalysisState(
      analysis: analysis ?? this.analysis,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ClimateAnalysisNotifier extends StateNotifier<ClimateAnalysisState> {
  final GetClimateAnalysis _getAnalysis;

  ClimateAnalysisNotifier(this._getAnalysis)
      : super(const ClimateAnalysisState());

  Future<void> loadAnalysis(String growId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _getAnalysis.call(growId);
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (data) => state = state.copyWith(
        isLoading: false,
        analysis: data,
      ),
    );
  }
}

final climateAnalysisProvider =
    StateNotifierProvider<ClimateAnalysisNotifier, ClimateAnalysisState>((ref) {
  return ClimateAnalysisNotifier(ref.watch(getClimateAnalysisUseCaseProvider));
});
