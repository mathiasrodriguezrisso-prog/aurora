/// UseCase: Completar una tarea del cultivo.
library;

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/grow_task_model.dart';
import '../repositories/grow_repository.dart';

class CompleteTask {
  final GrowRepository _repository;

  CompleteTask(this._repository);

  Future<Either<Failure, GrowTaskModel>> call(String growId, String taskId) {
    return _repository.completeTask(growId, taskId);
  }
}
