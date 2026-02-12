
import 'package:flutter/material.dart';
import '../../core/config/app_theme.dart';

// RE-IMPLEMENTING SHIMMER LOADING TO MATCH FIX
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

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
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

class _ShimmerCircle extends StatelessWidget {
  final double size;
  const _ShimmerCircle({required this.size});
  @override
  Widget build(BuildContext context) => ClipOval(child: ShimmerLoading(width: size, height: size, borderRadius: 0));
}
// Note: More specialized Shimmer widgets (PostCard, etc) would go here based on previous Context
