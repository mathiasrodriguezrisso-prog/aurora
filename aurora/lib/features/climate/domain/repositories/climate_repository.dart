/// Contrato del repositorio para Climate Analytics.
library;

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/climate_analysis_entity.dart';
import '../entities/climate_current_entity.dart';
import '../entities/climate_history_entity.dart';
import '../entities/climate_reading_entity.dart';

abstract class ClimateRepository {
  /// Registra una nueva lectura climática manual.
  Future<Either<Failure, ClimateReadingEntity>> addReading({
    required String growId,
    required double temperature,
    required double humidity,
    double? ph,
    double? ec,
    bool watered = false,
    String? notes,
  });

  /// Obtiene la lectura actual y los rangos ideales de la fase.
  Future<Either<Failure, ClimateCurrentEntity>> getCurrent(String growId);

  /// Obtiene el historial histórico de lecturas y estadísticas.
  Future<Either<Failure, ClimateHistoryEntity>> getHistory(
    String growId, {
    int days = 7,
  });

  /// Obtiene el análisis inteligente (IA) del clima.
  Future<Either<Failure, ClimateAnalysisEntity>> getAnalysis(String growId);
}
