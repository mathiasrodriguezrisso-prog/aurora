/// UseCase: Obtener análisis inteligente del clima.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/climate_analysis_entity.dart';
import '../../domain/repositories/climate_repository.dart';

class GetClimateAnalysis {
  final ClimateRepository _repository;

  GetClimateAnalysis(this._repository);

  Future<Either<Failure, ClimateAnalysisEntity>> call(String growId) {
    return _repository.getAnalysis(growId);
  }
}
