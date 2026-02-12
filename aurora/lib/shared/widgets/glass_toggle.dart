/// Toggle/switch con estética glass y glow neón.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/config/app_theme.dart';

class GlassToggle extends StatelessWidget {
  final bool value;
  final String label;
  final IconData? icon;
  final ValueChanged<bool> onChanged;

  const GlassToggle({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: value ? AppTheme.primary : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: value ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: AppTheme.primary,
            trackColor: AppTheme.glassBackground,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
