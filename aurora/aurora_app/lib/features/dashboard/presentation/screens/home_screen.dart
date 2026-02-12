
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/cycle_widget.dart';
import '../widgets/daily_ops_widget.dart';
import '../widgets/quick_stats_row.dart';
import '../widgets/aurora_tip_card.dart';
import '../widgets/community_highlight_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final activeGrowAsync = ref.watch(activeGrowProvider);
    final tasksAsync = ref.watch(dailyTasksProvider);
    final sensorAsync = ref.watch(latestSensorProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeGrowProvider);
          ref.invalidate(dailyTasksProvider);
          ref.invalidate(latestSensorProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         'Good morning,',
                         style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
                       ),
                       Text(
                         user?.userMetadata?['display_name'] ?? 'Grower',
                         style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                       ),
                     ],
                   ),
                   IconButton(
                     icon: const Badge(child: Icon(Icons.notifications_outlined, color: Colors.white)),
                     onPressed: () {},
                   ),
                ],
              ),
              
              const SizedBox(height: 24),

              // 2. Cycle Widget
              activeGrowAsync.when(
                data: (grow) => CycleWidget(growData: grow),
                loading: () => const ShimmerLoading(height: 180, borderRadius: 20),
                error: (_, __) => const CycleWidget(growData: null),
              ),

              const SizedBox(height: 16),

              // 3. Daily Ops
              tasksAsync.when(
                data: (tasks) => DailyOpsWidget(
                  tasks: tasks, 
                  onToggle: ref.read(toggleTaskProvider)
                ),
                loading: () => const ShimmerLoading(height: 150, borderRadius: 20),
                error: (e, __) => Text('Error loading tasks: $e', style: const TextStyle(color: Colors.red)),
              ),

              const SizedBox(height: 16),

              // 4. Quick Stats
              sensorAsync.when(
                data: (sensor) => QuickStatsRow(sensorData: sensor),
                loading: () => const Row(
                  children: [
                     Expanded(child: ShimmerLoading(height: 60)),
                     SizedBox(width: 8),
                     Expanded(child: ShimmerLoading(height: 60)),
                  ],
                ),
                error: (_, __) => const QuickStatsRow(sensorData: null),
              ),

              const SizedBox(height: 16),

              // 5. Aurora Tip
              const AuroraTipCard(),

              const SizedBox(height: 16),

              // 6. Community Highlight
              const CommunityHighlightWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
