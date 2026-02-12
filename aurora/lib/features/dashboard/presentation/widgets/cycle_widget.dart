/// Cycle Widget
/// Circular progress indicator showing current phase progress with
/// pulsing "Emerald Glow" effect and phase-aware coloring.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/config/app_theme.dart';

class CycleWidget extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final String currentPhase;
  final int daysInPhase;
  final int totalPhaseDays;
  final String strainName;
  final bool isOptimal;

  const CycleWidget({
    super.key,
    required this.progress,
    required this.currentPhase,
    required this.daysInPhase,
    required this.totalPhaseDays,
    required this.strainName,
    this.isOptimal = true,
  });

  @override
  State<CycleWidget> createState() => _CycleWidgetState();
}

class _CycleWidgetState extends State<CycleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _glowController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowController = AnimationController(
        duration: const Duration(seconds: 2), vsync: this)
      ..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(CycleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(begin: oldWidget.progress, end: widget.progress).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  /// Phase-based accent color (or error red if not optimal)
  Color get _phaseColor {
    if (!widget.isOptimal) return AppTheme.error;

    switch (widget.currentPhase.toLowerCase()) {
      case 'germination':
        return const Color(0xFF81C784); // soft green
      case 'seedling':
        return const Color(0xFF66BB6A); // bright green
      case 'vegetative':
      case 'veg':
        return AppTheme.primary; // emerald
      case 'flowering':
      case 'bloom':
        return const Color(0xFFBA68C8); // purple-pink
      case 'ripening':
        return const Color(0xFFFFB74D); // amber
      case 'drying':
      case 'curing':
        return const Color(0xFF8D6E63); // warm brown
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.glassBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.glassBorder),
              boxShadow: widget.isOptimal
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00FF88).withValues(
                          alpha: 0.1 + (_glowController.value * 0.2),
                        ),
                        blurRadius: 20 + (_glowController.value * 10),
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : [
                      // Sutil glow rojo si no es óptimo
                      BoxShadow(
                        color: const Color(0xFFFF4444).withValues(alpha: 0.15),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: child,
          );
        },
        child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT CYCLE',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.strainName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _phaseColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _phaseColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _phaseColor,
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scaleXY(begin: 1.0, end: 1.6, duration: 1200.ms)
                        .fadeIn(begin: 0.4, duration: 1200.ms),
                    const SizedBox(width: 6),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: _phaseColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            width: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulsing glow ring
                Container(
                  width: 196,
                  height: 196,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _phaseColor.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 1.0, end: 1.05, duration: 2000.ms, curve: Curves.easeInOut),

                // Background circle
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    color: AppTheme.surface.withValues(alpha: 0.3),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Progress circle
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: _animation.value,
                        strokeWidth: 12,
                        color: _phaseColor,
                        strokeCap: StrokeCap.round,
                      ),
                    );
                  },
                ),
                // Inner content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Day ${widget.daysInPhase}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'of ${widget.totalPhaseDays}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _phaseColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.currentPhase.toUpperCase(),
                        style: TextStyle(
                          color: _phaseColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
