
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/aurora_button.dart';
import '../../../../features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:go_router/go_router.dart';

import '../widgets/grow_timeline.dart';
import '../widgets/climate_analytics.dart';
import '../widgets/nutrition_tab.dart';
import '../widgets/grow_gallery.dart';

class GrowActiveScreen extends ConsumerWidget {
  const GrowActiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    final activeGrowAsync = ref.watch(activeGrowProvider);

    return activeGrowAsync.when(
      data: (grow) {
        if (grow == null) {
          return Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EmptyState(icon: Icons.eco_outlined, message: "No active grow"),
                    const SizedBox(height: 24),
                    AuroraButton(
                      text: "Start Growing",
                      onPressed: () => context.push('/grow/strain'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // grow is a Map<String, dynamic>
        // Depending on DB schema, name might be 'strain' or 'strain_name'
        final String strainName = grow['strain_name'] ?? grow['strain'] ?? 'My Grow';

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            backgroundColor: AppTheme.background,
            appBar: AppBar(
              title: Text(strainName),
              bottom: const TabBar(
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: Colors.white54,
                isScrollable: true,
                tabs: [
                  Tab(text: 'Timeline'),
                  Tab(text: 'Climate'),
                  Tab(text: 'Nutrition'),
                  Tab(text: 'Gallery'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                GrowTimeline(growData: grow),
                ClimateAnalytics(growId: grow['id']),
                NutritionTab(growData: grow),
                GrowGallery(growId: grow['id']),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      ),
      error: (e, stack) => Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }
}
