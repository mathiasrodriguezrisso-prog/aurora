/// 📁 lib/features/dashboard/data/repositories/dashboard_repository.dart
/// Dashboard repository — wraps data source with error handling.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/dashboard_remote_datasource.dart';

/// Dashboard data holder.
class DashboardData {
  final Map<String, dynamic>? activeGrow;
  final List<Map<String, dynamic>> dailyTasks;
  final Map<String, dynamic>? sensorData;
  final Map<String, dynamic>? growPlan;
  final Map<String, dynamic>? userProfile;
  final Map<String, dynamic>? auroraTip;

  const DashboardData({
    this.activeGrow,
    this.dailyTasks = const [],
    this.sensorData,
    this.growPlan,
    this.userProfile,
    this.auroraTip,
  });

  bool get hasActiveGrow => activeGrow != null;

  /// Calculate grow progress as 0.0 – 1.0.
  double get growProgress {
    if (activeGrow == null) return 0.0;
    final startDate = DateTime.tryParse(
      activeGrow!['start_date'] as String? ?? '',
    );
    final estimatedDays = activeGrow!['estimated_duration_days'] as int?;
    if (startDate == null || estimatedDays == null || estimatedDays <= 0) {
      return 0.0;
    }
    final elapsed = DateTime.now().difference(startDate).inDays;
    return (elapsed / estimatedDays).clamp(0.0, 1.0);
  }

  /// Get current day number.
  int get currentDay {
    if (activeGrow == null) return 0;
    final startDate = DateTime.tryParse(
      activeGrow!['start_date'] as String? ?? '',
    );
    if (startDate == null) return 0;
    return DateTime.now().difference(startDate).inDays + 1;
  }

  /// Completed tasks count.
  int get completedTaskCount =>
      dailyTasks.where((t) => t['is_completed'] == true).length;

  /// Current phase name.
  String get currentPhaseName {
    if (growPlan == null) return 'Unknown';
    final phases = growPlan!['phases'] as List<dynamic>? ?? [];
    for (final phase in phases) {
      if (phase['status'] == 'active' || phase['status'] == 'current') {
        return phase['name'] as String? ?? 'Unknown';
      }
    }
    return phases.isNotEmpty
        ? phases.first['name'] as String? ?? 'Unknown'
        : 'Unknown';
  }
}

/// Repository pattern for dashboard data.
class DashboardRepository {
  final DashboardRemoteDataSource _dataSource;

  DashboardRepository({required DashboardRemoteDataSource dataSource})
      : _dataSource = dataSource;

  /// Fetch all dashboard data in parallel.
  Future<DashboardData> fetchDashboard(String userId) async {
    try {
      // First get active grow
      final activeGrow = await _dataSource.fetchActiveGrow(userId);

      if (activeGrow == null) {
        // No active grow — return minimal data
        final profile = await _dataSource.fetchUserProfile(userId);
        return DashboardData(userProfile: profile);
      }

      final growId = activeGrow['id'] as String;

      // Fetch everything else in parallel
      final results = await Future.wait([
        _dataSource.fetchDailyTasks(growId, DateTime.now()),
        _dataSource.fetchLatestSensorData(growId),
        _dataSource.fetchGrowPlan(growId),
        _dataSource.fetchUserProfile(userId),
        _dataSource.fetchLatestAuroraTip(userId),
      ]);

      return DashboardData(
        activeGrow: activeGrow,
        dailyTasks:
            results[0] as List<Map<String, dynamic>>? ?? [],
        sensorData: results[1] as Map<String, dynamic>?,
        growPlan: results[2] as Map<String, dynamic>?,
        userProfile: results[3] as Map<String, dynamic>?,
        auroraTip: results[4] as Map<String, dynamic>?,
      );
    } catch (e) {
      throw DashboardException('Failed to load dashboard: $e');
    }
  }

  /// Toggle a task's completion.
  Future<void> toggleTask(String taskId, bool completed) async {
    await _dataSource.toggleTaskCompletion(taskId, completed);
  }
}

/// Repository provider.
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    dataSource: ref.watch(dashboardRemoteDataSourceProvider),
  );
});
