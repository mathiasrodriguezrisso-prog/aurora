/// 📁 lib/shared/widgets/shimmer_loading.dart
/// Shimmer loading effect with Aurora personality.
/// Includes generic ShimmerLoading + themed skeleton variants.
library;

import 'package:flutter/material.dart';

import '../../core/config/app_theme.dart';

// ============================================
// Base Shimmer
// ============================================

class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
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
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(1.0 + 2.0 * _controller.value, 0),
              colors: [
                AppTheme.surface.withValues(alpha: 0.3),
                AppTheme.primary.withValues(alpha: 0.08),
                AppTheme.surface.withValues(alpha: 0.3),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Circle shimmer helper (for avatars).
class _ShimmerCircle extends StatelessWidget {
  final double size;
  const _ShimmerCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: ShimmerLoading(width: size, height: size, borderRadius: 0),
    );
  }
}

// ============================================
// Generic ShimmerCard (existing)
// ============================================

class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(height: 16, width: 140),
          SizedBox(height: 12),
          ShimmerLoading(height: 120),
          SizedBox(height: 12),
          ShimmerLoading(height: 14, width: 200),
          SizedBox(height: 8),
          ShimmerLoading(height: 14, width: 160),
        ],
      ),
    );
  }
}

// ============================================
// ShimmerPostCard — simulates PostCard shape
// ============================================

class ShimmerPostCard extends StatelessWidget {
  const ShimmerPostCard({super.key});

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
          const ShimmerLoading(height: 200, width: double.infinity),
          const SizedBox(height: 12),
          Row(
            children: const [
              _ShimmerCircle(size: 32),
              SizedBox(width: 8),
              ShimmerLoading(height: 14, width: 120),
            ],
          ),
          const SizedBox(height: 8),
          const ShimmerLoading(height: 12, width: double.infinity),
          const SizedBox(height: 4),
          ShimmerLoading(
              height: 12, width: MediaQuery.of(context).size.width * 0.7),
          const SizedBox(height: 8),
          Row(
            children: const [
              ShimmerLoading(height: 14, width: 30),
              SizedBox(width: 20),
              ShimmerLoading(height: 14, width: 30),
              SizedBox(width: 20),
              ShimmerLoading(height: 14, width: 30),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================
// ShimmerDashboard — simulates home dashboard
// ============================================

class ShimmerDashboard extends StatelessWidget {
  const ShimmerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerLoading(height: 16, width: 200), // "Good morning"
          const SizedBox(height: 24),
          const Center(child: _ShimmerCircle(size: 160)), // Cycle
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
                4, (index) => const ShimmerLoading(height: 60, width: 75)),
          ),
          const SizedBox(height: 16),
          const ShimmerLoading(height: 120, width: double.infinity), // Ops
          const SizedBox(height: 16),
          const ShimmerLoading(height: 80, width: double.infinity), // Tip
        ],
      ),
    );
  }
}

// ============================================
// ShimmerProfileHeader — simulates profile top
// ============================================

class ShimmerProfileHeader extends StatelessWidget {
  const ShimmerProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        const _ShimmerCircle(size: 80),
        const SizedBox(height: 12),
        const ShimmerLoading(height: 16, width: 150),
        const SizedBox(height: 6),
        const ShimmerLoading(height: 12, width: 100),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            return Column(
              children: const [
                ShimmerLoading(height: 20, width: 40),
                SizedBox(height: 4),
                ShimmerLoading(height: 10, width: 50),
              ],
            );
          }),
        ),
      ],
    );
  }
}

// ============================================
// ShimmerList — N shimmer rows
// ============================================

class ShimmerList extends StatelessWidget {
  final int itemCount;
  const ShimmerList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: const [
              _ShimmerCircle(size: 40),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(height: 14),
                    SizedBox(height: 6),
                    ShimmerLoading(width: 160, height: 10),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
