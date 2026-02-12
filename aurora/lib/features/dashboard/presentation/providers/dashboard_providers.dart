/// 📁 lib/features/dashboard/presentation/providers/dashboard_providers.dart
/// Riverpod providers for dashboard state management.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository.dart';

// ─────────────────────────────────────────────────────
// Dashboard State
// ─────────────────────────────────────────────────────

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState {
  final DashboardStatus status;
  final DashboardData data;
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.data = const DashboardData(),
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardData? data,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }
}

// ─────────────────────────────────────────────────────
// Dashboard Notifier
// ─────────────────────────────────────────────────────

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardNotifier({required DashboardRepository repository})
      : _repository = repository,
        super(const DashboardState());

  /// Load all dashboard data.
  Future<void> loadDashboard() async {
    state = state.copyWith(status: DashboardStatus.loading);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(
          status: DashboardStatus.error,
          errorMessage: 'Not authenticated',
        );
        return;
      }

      final data = await _repository.fetchDashboard(userId);
      state = state.copyWith(
        status: DashboardStatus.loaded,
        data: data,
        errorMessage: null,
      );
    } on DashboardException catch (e) {
      state = state.copyWith(
        status: DashboardStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: DashboardStatus.error,
        errorMessage: 'Failed to load dashboard',
      );
    }
  }

  /// Refresh dashboard data (pull-to-refresh).
  Future<void> refresh() async {
    await loadDashboard();
  }

  /// Toggle a daily task completion.
  Future<void> toggleTask(String taskId, bool currentlyCompleted) async {
    // Optimistic update
    final updatedTasks = state.data.dailyTasks.map((t) {
      if (t['id'] == taskId) {
        return {...t, 'is_completed': !currentlyCompleted};
      }
      return t;
    }).toList();

    state = state.copyWith(
      data: DashboardData(
        activeGrow: state.data.activeGrow,
        dailyTasks: updatedTasks,
        sensorData: state.data.sensorData,
        growPlan: state.data.growPlan,
        userProfile: state.data.userProfile,
        auroraTip: state.data.auroraTip,
      ),
    );

    try {
      await _repository.toggleTask(taskId, !currentlyCompleted);
    } catch (e) {
      // Revert on failure
      final revertedTasks = state.data.dailyTasks.map((t) {
        if (t['id'] == taskId) {
          return {...t, 'is_completed': currentlyCompleted};
        }
        return t;
      }).toList();

      state = state.copyWith(
        data: DashboardData(
          activeGrow: state.data.activeGrow,
          dailyTasks: revertedTasks,
          sensorData: state.data.sensorData,
          growPlan: state.data.growPlan,
          userProfile: state.data.userProfile,
          auroraTip: state.data.auroraTip,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────

/// Main dashboard state provider.
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final notifier = DashboardNotifier(
    repository: ref.watch(dashboardRepositoryProvider),
  );
  // Auto-load on creation
  notifier.loadDashboard();
  return notifier;
});

/// Derived: active grow exists?
final hasActiveGrowProvider = Provider<bool>((ref) {
  return ref.watch(dashboardProvider).data.hasActiveGrow;
});

/// Derived: grow progress 0.0 – 1.0.
final growProgressProvider = Provider<double>((ref) {
  return ref.watch(dashboardProvider).data.growProgress;
});

/// Derived: daily tasks.
final dailyTasksProvider =
    Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(dashboardProvider).data.dailyTasks;
});

/// Derived: user display name.
final userDisplayNameProvider = Provider<String>((ref) {
  final profile = ref.watch(dashboardProvider).data.userProfile;
  return profile?['display_name'] as String? ??
      profile?['username'] as String? ??
      'Grower';
});
