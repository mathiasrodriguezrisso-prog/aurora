/// UseCase: Obtener el cultivo activo del usuario.
library;

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/grow_plan_model.dart';
import '../repositories/grow_repository.dart';

class GetActiveGrow {
  final GrowRepository _repository;

  GetActiveGrow(this._repository);

  Future<Either<Failure, List<GrowPlanModel>>> call() {
    return _repository.getActiveGrows();
  }
}
