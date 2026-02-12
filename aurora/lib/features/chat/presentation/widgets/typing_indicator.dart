import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/config/app_theme.dart';

/// Animated typing indicator (3 bouncing dots) for Dr. Aurora.
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 56, right: 48, top: 4, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return Padding(
                padding: EdgeInsets.only(right: index < 2 ? 4 : 0),
                child: _Dot(delay: Duration(milliseconds: index * 200)),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Single animated dot with staggered bounce.
class _Dot extends StatelessWidget {
  final Duration delay;
  const _Dot({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(),
        )
        .moveY(
          begin: 0,
          end: -6,
          duration: 400.ms,
          delay: delay,
          curve: Curves.easeInOut,
        )
        .then()
        .moveY(
          begin: -6,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeInOut,
        );
  }
}
