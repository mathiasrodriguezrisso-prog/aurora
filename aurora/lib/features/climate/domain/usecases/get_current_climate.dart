/// UseCase: Obtener clima actual e ideales.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/climate_current_entity.dart';
import '../../domain/repositories/climate_repository.dart';

class GetCurrentClimate {
  final ClimateRepository _repository;

  GetCurrentClimate(this._repository);

  Future<Either<Failure, ClimateCurrentEntity>> call(String growId) {
    return _repository.getCurrent(growId);
  }
}
