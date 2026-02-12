/// Proveedores de Riverpod para el módulo Grow.
/// Inyección de dependencias y StateNotifiers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/grow_remote_data_source.dart';
import '../../data/models/grow_plan_model.dart';
import '../../data/models/grow_task_model.dart';
import '../../data/repositories/grow_repository_impl.dart';
import '../../domain/repositories/grow_repository.dart';
import '../../domain/usecases/generate_grow_plan.dart';

// ─────────────────────────────────────────────────────
// Inyección de dependencias
// ─────────────────────────────────────────────────────

/// Datasource remoto de Grow.
final growRemoteDataSourceProvider = Provider<GrowRemoteDataSource>((ref) {
  final api = ref.watch(apiClientProvider);
  return GrowRemoteDataSourceImpl(api);
});

/// Repositorio de Grow.
final growRepositoryProvider = Provider<GrowRepository>((ref) {
  return GrowRepositoryImpl(ref.watch(growRemoteDataSourceProvider));
});

final generateGrowPlanProvider = Provider<GenerateGrowPlan>((ref) {
  return GenerateGrowPlan(ref.watch(growRepositoryProvider));
});

// ─────────────────────────────────────────────────────
// Estado del cultivo activo
// ─────────────────────────────────────────────────────

enum GrowStatus { initial, loading, loaded, empty, error }

class ActiveGrowState {
  final GrowStatus status;
  final GrowPlanModel? activeGrow;
  final String? errorMessage;

  const ActiveGrowState({
    this.status = GrowStatus.initial,
    this.activeGrow,
    this.errorMessage,
  });

  ActiveGrowState copyWith({
    GrowStatus? status,
    GrowPlanModel? activeGrow,
    String? errorMessage,
    bool clearGrow = false,
  }) {
    return ActiveGrowState(
      status: status ?? this.status,
      activeGrow: clearGrow ? null : (activeGrow ?? this.activeGrow),
      errorMessage: errorMessage,
    );
  }

  bool get hasActiveGrow => activeGrow != null;
  bool get isLoading => status == GrowStatus.loading;
}

class ActiveGrowNotifier extends StateNotifier<ActiveGrowState> {
  final GrowRepository _repository;

  ActiveGrowNotifier(this._repository) : super(const ActiveGrowState());

  /// Cargar el cultivo activo del usuario.
  Future<void> loadActiveGrow() async {
    state = state.copyWith(status: GrowStatus.loading);

    final result = await _repository.getActiveGrows();
    result.fold(
      (failure) => state = state.copyWith(
        status: GrowStatus.error,
        errorMessage: failure.message,
      ),
      (grows) {
        if (grows.isEmpty) {
          state = state.copyWith(status: GrowStatus.empty, clearGrow: true);
        } else {
          // Tomar el primer cultivo activo
          final active = grows.firstWhere(
            (g) => g.isActive,
            orElse: () => grows.first,
          );
          state = state.copyWith(
            status: GrowStatus.loaded,
            activeGrow: active,
          );
        }
      },
    );
  }

  /// Refrescar datos del cultivo activo.
  Future<void> refresh() async {
    await loadActiveGrow();
  }
}

/// Provider principal del cultivo activo.
final activeGrowProvider =
    StateNotifierProvider<ActiveGrowNotifier, ActiveGrowState>((ref) {
  final notifier = ActiveGrowNotifier(ref.watch(growRepositoryProvider));
  notifier.loadActiveGrow();
  return notifier;
});

/// Conveniencia: ¿tiene cultivo activo?
final hasActiveGrowDataProvider = Provider<bool>((ref) {
  return ref.watch(activeGrowProvider).hasActiveGrow;
});

// ─────────────────────────────────────────────────────
// Tareas del día
// ─────────────────────────────────────────────────────

class TodayTasksState {
  final GrowStatus status;
  final List<GrowTaskModel> tasks;
  final String? errorMessage;

  const TodayTasksState({
    this.status = GrowStatus.initial,
    this.tasks = const [],
    this.errorMessage,
  });

  TodayTasksState copyWith({
    GrowStatus? status,
    List<GrowTaskModel>? tasks,
    String? errorMessage,
  }) {
    return TodayTasksState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      errorMessage: errorMessage,
    );
  }

  int get completedCount => tasks.where((t) => t.isCompleted).length;
  int get totalCount => tasks.length;
  double get completionPercent =>
      totalCount == 0 ? 0 : completedCount / totalCount;
}

class TodayTasksNotifier extends StateNotifier<TodayTasksState> {
  final GrowRepository _repository;

  TodayTasksNotifier(this._repository) : super(const TodayTasksState());

  /// Cargar tareas del día para el cultivo activo.
  Future<void> loadTasks(String growId) async {
    state = state.copyWith(status: GrowStatus.loading);

    final result = await _repository.getTodayTasks(growId);
    result.fold(
      (failure) => state = state.copyWith(
        status: GrowStatus.error,
        errorMessage: failure.message,
      ),
      (tasks) => state = state.copyWith(
        status: GrowStatus.loaded,
        tasks: tasks,
      ),
    );
  }

  /// Completar una tarea con actualización optimista.
  Future<void> completeTask(String growId, String taskId) async {
    // Actualización optimista
    final updated = state.tasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(isCompleted: true, completedAt: DateTime.now());
      }
      return t;
    }).toList();
    state = state.copyWith(tasks: updated);

    final result = await _repository.completeTask(growId, taskId);
    result.fold(
      (failure) {
        // Revertir en caso de error
        final reverted = state.tasks.map((t) {
          if (t.id == taskId) {
            return t.copyWith(isCompleted: false);
          }
          return t;
        }).toList();
        state = state.copyWith(tasks: reverted, errorMessage: failure.message);
      },
      (_) {
        // Éxito — la actualización optimista ya se aplicó
      },
    );
  }
}

/// Provider de tareas del día.
final todayTasksProvider =
    StateNotifierProvider<TodayTasksNotifier, TodayTasksState>((ref) {
  final notifier = TodayTasksNotifier(ref.watch(growRepositoryProvider));
  // Cargar tareas cuando hay un cultivo activo
  final activeGrow = ref.watch(activeGrowProvider);
  if (activeGrow.hasActiveGrow) {
    notifier.loadTasks(activeGrow.activeGrow!.id);
  }
  return notifier;
});

// ─────────────────────────────────────────────────────
// Timeline y Historial (FutureProviders)
// ─────────────────────────────────────────────────────

/// Provider de timeline del cultivo activo.
final growTimelineProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, growId) async {
  final repo = ref.watch(growRepositoryProvider);
  final result = await repo.getTimeline(growId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (timeline) => timeline,
  );
});

/// Provider de historial de cultivos.
final growHistoryProvider = FutureProvider<List<GrowPlanModel>>((ref) async {
  final repo = ref.watch(growRepositoryProvider);
  final result = await repo.getHistory();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (history) => history,
  );
});
