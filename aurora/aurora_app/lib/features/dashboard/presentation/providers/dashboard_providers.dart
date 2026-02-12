import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:aurora_app/features/auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository.dart';

// 1. Data Source Provider
final dashboardDataSourceProvider = Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSource();
});

// 2. Repository Provider
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dashboardDataSourceProvider));
});

// 3. Active Grow Provider
final activeGrowProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    final user = ref.watch(authProvider).user;
    if (user == null) return null;
    return ref.watch(dashboardRepositoryProvider).fetchActiveGrow(user.id);
  } catch (e) {
    return null;
  }
});

// 4. Daily Tasks Provider
final dailyTasksProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  try {
    final growAsync = await ref.watch(activeGrowProvider.future);
    if (growAsync == null) return [];

    final growId = growAsync['id']?.toString() ?? '';
    if (growId.isEmpty) return [];
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return ref.watch(dashboardRepositoryProvider).fetchDailyTasks(growId, today);
  } catch (e) {
    return [];
  }
});

// 5. Latest Sensor Provider
final latestSensorProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    final growAsync = await ref.watch(activeGrowProvider.future);
    if (growAsync == null) return null;

    final growId = growAsync['id']?.toString() ?? '';
    if (growId.isEmpty) return null;

    return ref.watch(dashboardRepositoryProvider).fetchLatestSensor(growId);
  } catch (e) {
    return null;
  }
});

// 6. Toggle Task Logic
final toggleTaskProvider = Provider<void Function(String, bool)>((ref) {
  return (String taskId, bool completed) async {
    try {
      await ref.read(dashboardRepositoryProvider).toggleTaskCompletion(taskId, completed);
      ref.invalidate(dailyTasksProvider);
    } catch (e) {
      // Silently fail — UI remains unchanged
    }
  };
});
