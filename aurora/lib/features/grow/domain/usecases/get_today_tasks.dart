/// UseCase: Obtener las tareas del día.
library;

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/grow_task_model.dart';
import '../repositories/grow_repository.dart';

class GetTodayTasks {
  final GrowRepository _repository;

  GetTodayTasks(this._repository);

  Future<Either<Failure, List<GrowTaskModel>>> call(String growId) {
    return _repository.getTodayTasks(growId);
  }
}
