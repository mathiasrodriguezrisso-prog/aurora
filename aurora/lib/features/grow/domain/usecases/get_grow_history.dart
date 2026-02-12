/// UseCase: Obtener historial de cultivos completados.
library;

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/grow_plan_model.dart';
import '../repositories/grow_repository.dart';

class GetGrowHistory {
  final GrowRepository _repository;

  GetGrowHistory(this._repository);

  Future<Either<Failure, List<GrowPlanModel>>> call() {
    return _repository.getHistory();
  }
}
