/// 📁 lib/features/dashboard/presentation/screens/home_screen.dart
/// Dashboard principal de Aurora.
/// Conectado a datos reales via grow_providers y dashboard_providers.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_theme.dart';
import '../../../grow/data/models/grow_plan_model.dart';
import '../../../grow/data/models/grow_task_model.dart';
import '../../../grow/presentation/providers/grow_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/aurora_tip_card.dart';
import '../widgets/community_highlight_widget.dart';
import '../widgets/cycle_widget.dart';
import '../widgets/daily_ops_widget.dart';
import '../widgets/plant_status_widget.dart';
import '../widgets/quick_actions_widget.dart';
import '../widgets/quick_stats_row.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/empty_state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(dashboardProvider);
    final displayName = ref.watch(userDisplayNameProvider);
    final activeGrowState = ref.watch(activeGrowProvider);

    // Determinar color de fondo basado en la fase actual del cultivo
    final phaseName = activeGrowState.activeGrow?.currentPhase ?? '';
    final bg = _phaseBackgrounds[phaseName.toLowerCase()] ?? _defaultBg;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bg, _defaultBg],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(displayName),
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.surface,
                  onRefresh: _handleRefresh,
                  child: _buildBody(dashState, activeGrowState),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/chat'),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.auto_awesome, color: Colors.black),
      ),
    );
  }

  /// Pull to refresh — recarga datos del dashboard y del cultivo activo.
  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    await Future.wait([
      ref.read(dashboardProvider.notifier).refresh(),
      ref.read(activeGrowProvider.notifier).refresh(),
    ]);
  }

  Widget _buildHeader(String displayName) {
    final greeting = _getGreeting();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: Consumer(
                  builder: (context, ref, child) {
                    final unreadCount = ref.watch(unreadNotificationCountProvider);
                    return Badge(
                      label: Text(unreadCount.toString()),
                      isLabelVisible: unreadCount > 0,
                      backgroundColor: AppTheme.primary,
                      textColor: Colors.black,
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: AppTheme.textSecondary,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(DashboardState dashState, ActiveGrowState growState) {
    // Estado de loading
    if (dashState.status == DashboardStatus.loading &&
        growState.status == GrowStatus.loading) {
      return const ShimmerLoading();
    }

    // Estado de error
    if (dashState.status == DashboardStatus.error) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          EmptyState(
            icon: Icons.error_outline,
            title: 'Error al cargar',
            subtitle: dashState.errorMessage ?? 'Intenta de nuevo',
          ),
        ],
      );
    }

    // Sin cultivo activo
    if (!growState.hasActiveGrow) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          EmptyState(
            icon: Icons.eco_outlined,
            title: 'No tienes cultivos activos',
            subtitle: 'Inicia tu primer cultivo para ver tu dashboard',
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/grow-setup'),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo Cultivo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      );
    }

    // Dashboard con datos reales
    final grow = growState.activeGrow!;
    final todayState = ref.watch(todayTasksProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 8),
        // Progreso del ciclo
        CycleWidget(
          progress: grow.progress,
          currentPhase: grow.currentPhase,
          daysInPhase: grow.daysElapsed,
          totalPhaseDays: grow.estimatedTotalWeeks * 7,
          strainName: grow.strain,
        ),
        const SizedBox(height: 16),

        // Stats rápidos
        QuickStatsRow(
          currentDay: grow.daysElapsed,
          currentWeek: grow.currentWeek,
          completedTasks: todayState.completedCount,
          totalTasks: todayState.totalCount,
        ),
        const SizedBox(height: 16),

        // Tareas del día
        _buildDailyOps(todayState, grow.id),
        const SizedBox(height: 16),

        // Tip de Aurora
        if (dashState.data.auroraTip != null)
          AuroraTipCard(
            tip: dashState.data.auroraTip!['message'] as String? ?? '',
            category: dashState.data.auroraTip!['category'] as String? ?? 'general',
          ),
        const SizedBox(height: 16),

        // Acciones rápidas
        const QuickActionsWidget(),
        const SizedBox(height: 16),

        // Comunidad
        const CommunityHighlightWidget(),
        const SizedBox(height: 100), // Espacio para FAB
      ],
    );
  }

  /// Construye la lista de tareas diarias conectada al grow provider real.
  Widget _buildDailyOps(TodayTasksState todayState, String growId) {
    if (todayState.status == GrowStatus.loading) {
      return const ShimmerLoading();
    }

    // Convertir GrowTaskModel a DailyTask (widget existente)
    final dailyTasks = todayState.tasks.map((t) {
      return DailyTask(
        id: t.id,
        title: '${t.categoryIcon} ${t.action}',
        time: t.detail,
        isCompleted: t.isCompleted,
        isCritical: t.isHighPriority,
      );
    }).toList();

    return DailyOpsWidget(
      tasks: dailyTasks,
      onTaskToggle: (taskId) {
        ref.read(todayTasksProvider.notifier).completeTask(growId, taskId);
      },
    );
  }

  /// Saludo según la hora del día.
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '🌙 Buenas noches';
    if (hour < 12) return '☀️ Buenos días';
    if (hour < 19) return '🌤️ Buenas tardes';
    return '🌙 Buenas noches';
  }

  static const _defaultBg = Color(0xFF0A0A0F);

  static const _phaseBackgrounds = {
    'germination': Color(0xFF0A0A1F),
    'seedling': Color(0xFF0A0A1F),
    'vegetative': Color(0xFF0A1A0F),
    'veg': Color(0xFF0A1A0F),
    'pre_flower': Color(0xFF0F1A0A),
    'flowering': Color(0xFF1A0F0A),
    'bloom': Color(0xFF1A0F0A),
    'late_flower': Color(0xFF1A0A0F),
    'flushing': Color(0xFF0F0A1A),
    'drying': Color(0xFF0F0A1A),
    'curing': Color(0xFF0A0F1A),
  };
}
