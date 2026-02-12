/// Implementación del repositorio de Grow.
/// Orquesta el datasource y mapea excepciones a Failures.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/grow_repository.dart';
import '../datasources/grow_remote_data_source.dart';
import '../models/grow_plan_model.dart';
import '../models/grow_task_model.dart';
import '../models/grow_log_model.dart';

class GrowRepositoryImpl implements GrowRepository {
  final GrowRemoteDataSource remoteDataSource;

  GrowRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, GrowPlanModel>> generatePlan(Map<String, dynamic> config) async {
    try {
      final plan = await remoteDataSource.generatePlan(config);
      return right(plan);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return left(NetworkFailure(e.message));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GrowPlanModel>> getGrowPlan(String growId) async {
    try {
      final plan = await remoteDataSource.getGrowPlan(growId);
      return right(plan);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return left(NetworkFailure(e.message));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GrowPlanModel>>> getActiveGrows() async {
    try {
      final grows = await remoteDataSource.getActiveGrows();
      return right(grows);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return left(NetworkFailure(e.message));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GrowTaskModel>>> getTodayTasks(String growId) async {
    try {
      final tasks = await remoteDataSource.getTodayTasks(growId);
      return right(tasks);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return left(NetworkFailure(e.message));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GrowTaskModel>> completeTask(String growId, String taskId) async {
    try {
      final task = await remoteDataSource.completeTask(growId, taskId);
      return right(task);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return left(NetworkFailure(e.message));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GrowLogModel>> addDailyLog(String growId, Map<String, dynamic> logData) async {
    try {
      final log = await remoteDataSource.addDailyLog(growId, logData);
      return right(log);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return left(NetworkFailure(e.message));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GrowPlanModel>> adjustPlan(
      String growId, Map<String, dynamic> adjustments) async {
    try {
      final plan = await remoteDataSource.adjustPlan(growId, adjustments);
      return right(plan);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return left(NetworkFailure(e.message));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getTimeline(String growId) async {
    try {
      final timeline = await remoteDataSource.getTimeline(growId);
      return right(timeline);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return left(NetworkFailure(e.message));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GrowPlanModel>> harvestGrow(
      String growId, Map<String, dynamic> harvestData) async {
    try {
      final grow = await remoteDataSource.harvestGrow(growId, harvestData);
      return right(grow);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return left(NetworkFailure(e.message));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GrowPlanModel>>> getHistory() async {
    try {
      final history = await remoteDataSource.getHistory();
      return right(history);
    } on ServerException catch (e) {
      return left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return left(NetworkFailure(e.message));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }
}
