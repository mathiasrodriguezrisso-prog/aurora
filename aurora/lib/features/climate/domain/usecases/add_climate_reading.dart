/// UseCase: Registrar una lectura climática.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/climate_reading_entity.dart';
import '../../domain/repositories/climate_repository.dart';

class AddClimateReading {
  final ClimateRepository _repository;

  AddClimateReading(this._repository);

  Future<Either<Failure, ClimateReadingEntity>> call({
    required String growId,
    required double temperature,
    required double humidity,
    double? ph,
    double? ec,
    bool watered = false,
    String? notes,
  }) {
    return _repository.addReading(
      growId: growId,
      temperature: temperature,
      humidity: humidity,
      ph: ph,
      ec: ec,
      watered: watered,
      notes: notes,
    );
  }
}
