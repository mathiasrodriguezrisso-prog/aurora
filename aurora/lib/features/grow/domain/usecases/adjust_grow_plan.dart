/// UseCase: Ajustar un plan de cultivo.
library;

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/grow_plan_model.dart';
import '../repositories/grow_repository.dart';

class AdjustGrowPlan {
  final GrowRepository _repository;

  AdjustGrowPlan(this._repository);

  Future<Either<Failure, GrowPlanModel>> call(
      String growId, Map<String, dynamic> adjustments) {
    return _repository.adjustPlan(growId, adjustments);
  }
}
