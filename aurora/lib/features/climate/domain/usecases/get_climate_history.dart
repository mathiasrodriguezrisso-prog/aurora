/// UseCase: Obtener historial climático.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/climate_history_entity.dart';
import '../../domain/repositories/climate_repository.dart';

class GetClimateHistory {
  final ClimateRepository _repository;

  GetClimateHistory(this._repository);

  Future<Either<Failure, ClimateHistoryEntity>> call(String growId, {int days = 7}) {
    return _repository.getHistory(growId, days: days);
  }
}
