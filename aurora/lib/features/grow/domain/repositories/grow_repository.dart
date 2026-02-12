/// Contrato para operaciones del módulo Grow.
/// Implementado por GrowRepositoryImpl en la capa de datos.
library;

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../data/models/grow_plan_model.dart';
import '../../data/models/grow_task_model.dart';
import '../../data/models/grow_log_model.dart';

abstract class GrowRepository {
  /// Genera un plan de cultivo con IA.
  Future<Either<Failure, GrowPlanModel>> generatePlan(Map<String, dynamic> config);

  /// Obtiene un cultivo por ID.
  Future<Either<Failure, GrowPlanModel>> getGrowPlan(String growId);

  /// Obtiene todos los cultivos activos del usuario.
  Future<Either<Failure, List<GrowPlanModel>>> getActiveGrows();

  /// Obtiene las tareas del día para un cultivo.
  Future<Either<Failure, List<GrowTaskModel>>> getTodayTasks(String growId);

  /// Marca una tarea como completada.
  Future<Either<Failure, GrowTaskModel>> completeTask(String growId, String taskId);

  /// Agrega un registro diario al cultivo.
  Future<Either<Failure, GrowLogModel>> addDailyLog(String growId, Map<String, dynamic> logData);

  /// Ajusta el plan de cultivo.
  Future<Either<Failure, GrowPlanModel>> adjustPlan(String growId, Map<String, dynamic> adjustments);

  /// Obtiene la línea de tiempo del cultivo.
  Future<Either<Failure, List<Map<String, dynamic>>>> getTimeline(String growId);

  /// Marca el cultivo como cosechado.
  Future<Either<Failure, GrowPlanModel>> harvestGrow(String growId, Map<String, dynamic> harvestData);

  /// Obtiene el historial de cultivos completados.
  Future<Either<Failure, List<GrowPlanModel>>> getHistory();
}
