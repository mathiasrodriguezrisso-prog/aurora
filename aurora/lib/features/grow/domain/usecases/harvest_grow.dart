/// UseCase: Marcar un cultivo como cosechado.
library;

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/grow_plan_model.dart';
import '../repositories/grow_repository.dart';

class HarvestGrow {
  final GrowRepository _repository;

  HarvestGrow(this._repository);

  Future<Either<Failure, GrowPlanModel>> call(
      String growId, Map<String, dynamic> harvestData) {
    return _repository.harvestGrow(growId, harvestData);
  }
}
