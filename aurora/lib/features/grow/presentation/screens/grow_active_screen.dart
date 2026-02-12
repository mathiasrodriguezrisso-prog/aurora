/// 📁 lib/features/grow/presentation/screens/grow_active_screen.dart
/// Active grow screen with 4 tabs: Timeline, Climate, Nutrition, Gallery.
/// Reads grow data from Supabase via providers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_theme.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../widgets/climate_analytics.dart';
import '../widgets/grow_gallery.dart';
import '../widgets/grow_timeline.dart';
import '../widgets/nutrition_tab.dart';

class GrowActiveScreen extends ConsumerStatefulWidget {
  const GrowActiveScreen({super.key});

  @override
  ConsumerState<GrowActiveScreen> createState() => _GrowActiveScreenState();
}

class _GrowActiveScreenState extends ConsumerState<GrowActiveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = ['Timeline', 'Climate', 'Nutrition', 'Gallery'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(dashboardProvider);
    final hasGrow = dashState.data.hasActiveGrow;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: hasGrow ? _buildContent(dashState) : _buildEmptyState(),
        ),
      ),
    );
  }

  Widget _buildContent(DashboardState state) {
    final growName = state.data.activeGrow?['name'] as String? ?? 'My Grow';

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            children: [
              const Icon(Icons.eco_rounded, color: AppTheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      growName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Day ${state.data.currentDay} • ${state.data.currentPhaseName}',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.auto_awesome, color: AppTheme.primary),
                onPressed: () => context.push('/chat'),
                tooltip: 'Ask Dr. Aurora',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Tab Bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppTheme.glassBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textTertiary,
            indicatorColor: AppTheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
            ),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              GrowTimeline(growPlan: state.data.growPlan),
              ClimateAnalytics(
                sensorData: state.data.sensorData,
                growId: state.data.activeGrow?['id'] as String? ?? '',
              ),
              NutritionTab(
                growPlan: state.data.growPlan,
                growId: state.data.activeGrow?['id'] as String? ?? '',
                currentPhase: state.data.currentPhaseName,
              ),
              GrowGallery(
                growId: state.data.activeGrow?['id'] as String? ?? '',
                currentDay: state.data.currentDay,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_outlined,
              size: 80,
              color: AppTheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Grow',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Create a new grow plan to get started with your cultivation journey.',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/grow-setup'),
              icon: const Icon(Icons.add),
              label: const Text('Start New Grow'),
            ),
          ],
        ),
      ),
    );
  }
}
