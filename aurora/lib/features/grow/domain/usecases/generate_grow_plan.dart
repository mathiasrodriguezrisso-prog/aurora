/// UseCase: Generar un plan de cultivo con IA.
library;

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/grow_plan_model.dart';
import '../repositories/grow_repository.dart';

class GenerateGrowPlan {
  final GrowRepository _repository;

  GenerateGrowPlan(this._repository);

  Future<Either<Failure, GrowPlanModel>> call(Map<String, dynamic> config) {
    return _repository.generatePlan(config);
  }
}
