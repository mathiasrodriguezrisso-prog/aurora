/// UseCase: Agregar un registro diario al cultivo.
library;

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/grow_log_model.dart';
import '../repositories/grow_repository.dart';

class AddDailyLog {
  final GrowRepository _repository;

  AddDailyLog(this._repository);

  Future<Either<Failure, GrowLogModel>> call(String growId, Map<String, dynamic> logData) {
    return _repository.addDailyLog(growId, logData);
  }
}
