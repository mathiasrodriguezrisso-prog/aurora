
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;

  DashboardRepository(this._remoteDataSource);

  Future<Map<String, dynamic>?> fetchActiveGrow(String userId) async {
    try {
      return await _remoteDataSource.fetchActiveGrow(userId);
    } catch (e) {
      print('Fetch Active Grow Error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchDailyTasks(String growId, String date) async {
    try {
      return await _remoteDataSource.fetchDailyTasks(growId, date);
    } catch (e) {
      print('Fetch Tasks Error: $e');
      return [];
    }
  }

  Future<void> toggleTaskCompletion(String taskId, bool completed) async {
    try {
      await _remoteDataSource.toggleTaskCompletion(taskId, completed);
    } catch (e) {
      print('Toggle Task Error: $e');
      throw Exception(e); // Rethrow to update UI optimally if needed
    }
  }

  Future<Map<String, dynamic>?> fetchLatestSensor(String growId) async {
    try {
      return await _remoteDataSource.fetchLatestSensor(growId);
    } catch (e) {
      print('Fetch Sensor Error: $e');
      return null;
    }
  }
}
