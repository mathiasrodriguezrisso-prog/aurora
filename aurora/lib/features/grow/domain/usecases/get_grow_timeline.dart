/// UseCase: Obtener la línea de tiempo del cultivo.
library;

import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/grow_repository.dart';

class GetGrowTimeline {
  final GrowRepository _repository;

  GetGrowTimeline(this._repository);

  Future<Either<Failure, List<Map<String, dynamic>>>> call(String growId) {
    return _repository.getTimeline(growId);
  }
}
