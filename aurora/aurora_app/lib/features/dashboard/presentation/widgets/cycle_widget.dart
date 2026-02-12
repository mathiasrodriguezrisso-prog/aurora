
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/aurora_button.dart';

class CycleWidget extends StatelessWidget {
  final Map<String, dynamic>? growData;

  const CycleWidget({super.key, required this.growData});

  @override
  Widget build(BuildContext context) {
    if (growData == null) {
      return GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.eco_rounded, size: 48, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'No Active Grow',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start your journey with Aurora.',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            AuroraButton(
              text: 'Start New Grow',
              onPressed: () => context.push('/grow'), // Adjusted route if needed
            )
          ],
        ),
      );
    }

    final int dayNumber = growData!['day_number'] ?? 1;
    final int totalDays = growData!['total_days'] ?? 90;
    final String phase = growData!['current_phase'] ?? 'Seedling';
    final String strain = growData!['strain_name'] ?? 'Unknown Strain';
    final double progress = (dayNumber / totalDays).clamp(0.0, 1.0);

    return GlassContainer(
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: AppTheme.surface,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Day $dayNumber',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'of $totalDays',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(phase, style: const TextStyle(color: AppTheme.primary, fontSize: 18, fontWeight: FontWeight.w600)),
          Text(strain, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}
