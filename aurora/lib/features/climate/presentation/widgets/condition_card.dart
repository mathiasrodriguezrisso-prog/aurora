/// Tarjeta para mostrar una condición climática individual.
library;

import 'package:flutter/material.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';

class ConditionCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? trend; // 'up', 'down', 'stable'
  final bool isAlert;

  const ConditionCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.trend,
    this.isAlert = false,
  });

  @override
  State<ConditionCard> createState() => _ConditionCardState();
}

class _ConditionCardState extends State<ConditionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _alertController;
  late Animation<Color?> _borderAnimation;

  @override
  void initState() {
    super.initState();
    _alertController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _borderAnimation = ColorTween(
      begin: AppTheme.glassBorder,
      end: AppTheme.error,
    ).animate(CurvedAnimation(
      parent: _alertController,
      curve: Curves.easeInOut,
    ));

    if (widget.isAlert) {
      _alertController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant ConditionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAlert != oldWidget.isAlert) {
      if (widget.isAlert) {
        _alertController.repeat(reverse: true);
      } else {
        _alertController.stop();
        _alertController.reset();
      }
    }
  }

  @override
  void dispose() {
    _alertController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _borderAnimation,
      builder: (context, child) {
        return GlassCard(
          borderColor: widget.isAlert
              ? _borderAnimation.value
              : AppTheme.glassBorder,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(widget.icon, color: widget.iconColor, size: 20),
                    if (widget.trend != null)
                      Icon(
                        _getTrendIcon(widget.trend!),
                        color: _getTrendColor(widget.trend!),
                        size: 16,
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  widget.value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'up':
        return Icons.arrow_upward;
      case 'down':
        return Icons.arrow_downward;
      default:
        return Icons.remove;
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'up':
        return const Color(0xFFFFA726); // Naranja (subida)
      case 'down':
        return const Color(0xFF4FC3F7); // Celeste (bajada)
      default:
        return AppTheme.textSecondary;
    }
  }
}
