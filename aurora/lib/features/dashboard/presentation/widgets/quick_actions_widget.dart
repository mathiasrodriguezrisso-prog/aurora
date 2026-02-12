/// Quick Actions Widget
/// Grid of buttons for common actions.
library;

import 'package:flutter/material.dart';
import '../../../../core/config/app_theme.dart';

class QuickActionsWidget extends StatelessWidget {
  final VoidCallback onLogFeed;
  final VoidCallback onAddPhoto;
  final VoidCallback onReportIssue;
  final VoidCallback onSettings;

  const QuickActionsWidget({
    super.key,
    required this.onLogFeed,
    required this.onAddPhoto,
    required this.onReportIssue,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'QUICK ACTIONS',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ActionButton(
              icon: Icons.opacity,
              label: 'Water/Feed',
              onTap: onLogFeed,
              color: AppTheme.primary,
            ),
            _ActionButton(
              icon: Icons.camera_alt,
              label: 'Add Photo',
              onTap: onAddPhoto,
              color: const Color(0xFF9B59B6),
            ),
            _ActionButton(
              icon: Icons.warning_amber,
              label: 'Problem',
              onTap: onReportIssue,
              color: AppTheme.error,
            ),
            _ActionButton(
              icon: Icons.settings,
              label: 'Settings',
              onTap: onSettings,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.glassBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.glassBorder),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
