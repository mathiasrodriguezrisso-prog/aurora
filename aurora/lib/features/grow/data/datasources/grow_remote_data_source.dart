/// Datasource remoto para el módulo Grow.
/// Usa ApiClient (Dio) con JWT automático.
library;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/grow_plan_model.dart';
import '../models/grow_task_model.dart';
import '../models/grow_log_model.dart';

/// Interfaz del datasource remoto de Grow.
abstract class GrowRemoteDataSource {
  Future<GrowPlanModel> generatePlan(Map<String, dynamic> config);
  Future<GrowPlanModel> getGrowPlan(String growId);
  Future<List<GrowPlanModel>> getActiveGrows();
  Future<List<GrowTaskModel>> getTodayTasks(String growId);
  Future<GrowTaskModel> completeTask(String growId, String taskId);
  Future<GrowLogModel> addDailyLog(String growId, Map<String, dynamic> logData);
  Future<GrowPlanModel> adjustPlan(String growId, Map<String, dynamic> adjustments);
  Future<List<Map<String, dynamic>>> getTimeline(String growId);
  Future<GrowPlanModel> harvestGrow(String growId, Map<String, dynamic> harvestData);
  Future<List<GrowPlanModel>> getHistory();
}

/// Implementación usando ApiClient (Dio).
class GrowRemoteDataSourceImpl implements GrowRemoteDataSource {
  final ApiClient _api;

  GrowRemoteDataSourceImpl(this._api);

  @override
  Future<GrowPlanModel> generatePlan(Map<String, dynamic> config) async {
    // LOG TEMPORAL: Ver qué se envía exactamente
    try {
      // ignore: avoid_print
      print('🌱 ====== GENERATE PLAN REQUEST ======');
      // ignore: avoid_print
      print('🌱 URL: /api/v1/grow/generate-plan');
      // ignore: avoid_print
      print('🌱 Data: $config');
      config.forEach((key, value) {
        // ignore: avoid_print
        print('🌱   $key: $value (${value.runtimeType})');
      });
      // ignore: avoid_print
      print('🌱 ====================================');

      final response = await _api.post<Map<String, dynamic>>(
        '/api/v1/grow/generate-plan',
        data: config,
      );
      final data = response.data!;
      if (data['success'] != true) {
        throw ServerException(
          data['message'] as String? ?? 'Error al generar plan',
          statusCode: response.statusCode,
        );
      }
      final planData = data['plan'] as Map<String, dynamic>;
      return GrowPlanModel.fromJson(planData);
    } on ApiException catch (e) {
      // ignore: avoid_print
      print('🌱 ❌ ERROR en generate-plan: $e');
      throw ServerException(e.message, statusCode: e.statusCode);
    } catch (e) {
      // ignore: avoid_print
      print('🌱 ❌ ERROR inesperado en generate-plan: $e');
      rethrow;
    }
  }

  @override
  Future<GrowPlanModel> getGrowPlan(String growId) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/v1/grow/$growId',
      );
      final data = response.data!;
      return GrowPlanModel.fromJson(data['grow'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw ServerException(e.message, statusCode: e.statusCode);
    }
  }

  @override
  Future<List<GrowPlanModel>> getActiveGrows() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/v1/grow/active',
      );
      final data = response.data!;
      final grows = data['grows'] as List<dynamic>;
      return grows
          .map((g) => GrowPlanModel.fromJson(g as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      throw ServerException(e.message, statusCode: e.statusCode);
    }
  }

  @override
  Future<List<GrowTaskModel>> getTodayTasks(String growId) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/v1/grow/$growId/tasks/today',
      );
      final data = response.data!;
      final tasks = data['tasks'] as List<dynamic>;
      return tasks
          .map((t) => GrowTaskModel.fromJson(t as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      throw ServerException(e.message, statusCode: e.statusCode);
    }
  }

  @override
  Future<GrowTaskModel> completeTask(String growId, String taskId) async {
    try {
      final response = await _api.put<Map<String, dynamic>>(
        '/api/v1/grow/$growId/tasks/$taskId',
        data: {'is_completed': true, 'completed_at': DateTime.now().toIso8601String()},
      );
      final data = response.data!;
      return GrowTaskModel.fromJson(data['task'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw ServerException(e.message, statusCode: e.statusCode);
    }
  }

  @override
  Future<GrowLogModel> addDailyLog(String growId, Map<String, dynamic> logData) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/api/v1/grow/$growId/log',
        data: logData,
      );
      final data = response.data!;
      return GrowLogModel.fromJson(data['log'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw ServerException(e.message, statusCode: e.statusCode);
    }
  }

  @override
  Future<GrowPlanModel> adjustPlan(String growId, Map<String, dynamic> adjustments) async {
    try {
      final response = await _api.put<Map<String, dynamic>>(
        '/api/v1/grow/$growId/adjust',
        data: adjustments,
      );
      final data = response.data!;
      return GrowPlanModel.fromJson(data['grow'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw ServerException(e.message, statusCode: e.statusCode);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTimeline(String growId) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/v1/grow/$growId/timeline',
      );
      final data = response.data!;
      final events = data['timeline'] as List<dynamic>;
      return events.cast<Map<String, dynamic>>();
    } on ApiException catch (e) {
      throw ServerException(e.message, statusCode: e.statusCode);
    }
  }

  @override
  Future<GrowPlanModel> harvestGrow(String growId, Map<String, dynamic> harvestData) async {
    try {
      final response = await _api.put<Map<String, dynamic>>(
        '/api/v1/grow/$growId/harvest',
        data: harvestData,
      );
      final data = response.data!;
      return GrowPlanModel.fromJson(data['grow'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      throw ServerException(e.message, statusCode: e.statusCode);
    }
  }

  @override
  Future<List<GrowPlanModel>> getHistory() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/v1/grow/history',
      );
      final data = response.data!;
      final grows = data['grows'] as List<dynamic>;
      return grows
          .map((g) => GrowPlanModel.fromJson(g as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      throw ServerException(e.message, statusCode: e.statusCode);
    }
  }
}
