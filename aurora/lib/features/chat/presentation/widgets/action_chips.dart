import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/config/app_theme.dart';

/// Quick action chips for Dr. Aurora chat.
/// "Show Diagnostics", "Adjust Plan", "Take Photo"
class ActionChips extends StatelessWidget {
  final VoidCallback onDiagnostics;
  final VoidCallback onAdjustPlan;
  final VoidCallback onTakePhoto;

  const ActionChips({
    super.key,
    required this.onDiagnostics,
    required this.onAdjustPlan,
    required this.onTakePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _GlassChip(
            icon: Icons.analytics_outlined,
            label: 'Diagnostics',
            onTap: onDiagnostics,
          ),
          const SizedBox(width: 8),
          _GlassChip(
            icon: Icons.tune_rounded,
            label: 'Adjust Plan',
            onTap: onAdjustPlan,
          ),
          const SizedBox(width: 8),
          _GlassChip(
            icon: Icons.camera_alt_outlined,
            label: 'Take Photo',
            onTap: onTakePhoto,
          ),
        ],
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
