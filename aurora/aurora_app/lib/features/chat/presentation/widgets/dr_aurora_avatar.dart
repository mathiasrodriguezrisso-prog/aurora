
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/config/app_theme.dart';

class DrAuroraAvatar extends StatelessWidget {
  final double size;
  final bool isThinking;

  const DrAuroraAvatar({
    super.key,
    this.size = 40,
    this.isThinking = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primary.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome,
          color: AppTheme.primary,
          size: size * 0.6,
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .scale(duration: 2.seconds, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2))
         .then()
         .shimmer(duration: 2.seconds, color: Colors.white),
      ),
    );
  }
}
