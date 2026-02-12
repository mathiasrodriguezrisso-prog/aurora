/// 📁 lib/shared/widgets/aurora_shimmer.dart
/// Skeleton loading shimmer with Aurora's green personality.
/// Usage: `AuroraShimmer(width: 200, height: 16)` or `AuroraShimmer.circle(size: 40)`
library;

import 'package:flutter/material.dart';
import '../../core/config/app_theme.dart';

class AuroraShimmer extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const AuroraShimmer({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  /// Circular shimmer (for avatars)
  const AuroraShimmer.circle({
    super.key,
    double size = 40,
  })  : width = size,
        height = size,
        borderRadius = 999;

  @override
  State<AuroraShimmer> createState() => _AuroraShimmerState();
}

class _AuroraShimmerState extends State<AuroraShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [
                AppTheme.surface.withValues(alpha: 0.3),
                AppTheme.primary.withValues(alpha: 0.08),
                AppTheme.surface.withValues(alpha: 0.3),
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        );
      },
    );
  }
}

/// Pre-built skeleton for a post card
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              const AuroraShimmer.circle(size: 36),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AuroraShimmer(width: 100, height: 12),
                  SizedBox(height: 6),
                  AuroraShimmer(width: 60, height: 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Content lines
          const AuroraShimmer(height: 12),
          const SizedBox(height: 6),
          const AuroraShimmer(width: 240, height: 12),
          const SizedBox(height: 12),
          // Image placeholder
          const AuroraShimmer(height: 180, borderRadius: 12),
          const SizedBox(height: 12),
          // Action row
          Row(
            children: const [
              AuroraShimmer(width: 50, height: 12),
              SizedBox(width: 16),
              AuroraShimmer(width: 50, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}
