import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/config/app_theme.dart';

/// Dr. Aurora avatar state enum.
enum AvatarState { normal, thinking, alert }

/// Animated Dr. Aurora avatar with state-driven glow ring.
class DrAuroraAvatar extends StatelessWidget {
  final double size;
  final AvatarState state;

  const DrAuroraAvatar({
    super.key,
    this.size = 40,
    this.state = AvatarState.normal,
  });

  Color get _glowColor {
    switch (state) {
      case AvatarState.thinking:
        return AppTheme.secondary;
      case AvatarState.alert:
        return AppTheme.error;
      case AvatarState.normal:
        return AppTheme.primary;
    }
  }

  IconData get _icon {
    switch (state) {
      case AvatarState.thinking:
        return Icons.psychology_rounded;
      case AvatarState.alert:
        return Icons.warning_rounded;
      case AvatarState.normal:
        return Icons.local_florist_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing glow ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _glowColor.withValues(alpha: 0.4),
                width: state == AvatarState.alert ? 2.5 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _glowColor.withValues(alpha: 0.3),
                  blurRadius: state == AvatarState.alert ? 14 : 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          )
              .animate(
                onPlay: (c) => c.repeat(reverse: true),
              )
              .scaleXY(
                begin: 1.0,
                end: state == AvatarState.thinking ? 1.15 : 1.1,
                duration: state == AvatarState.thinking ? 800.ms : 1500.ms,
                curve: Curves.easeInOut,
              )
              .fadeIn(
                begin: 0.6,
                duration: state == AvatarState.thinking ? 800.ms : 1500.ms,
                curve: Curves.easeInOut,
              ),

          // Inner circle with icon
          Container(
            width: size * 0.85,
            height: size * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _glowColor.withValues(alpha: 0.2),
                  _glowColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: _glowColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: state == AvatarState.thinking
                ? Icon(
                    _icon,
                    size: size * 0.45,
                    color: _glowColor,
                  )
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(
                      begin: -0.02,
                      end: 0.02,
                      duration: 400.ms,
                      curve: Curves.easeInOut,
                    )
                : Icon(
                    _icon,
                    size: size * 0.45,
                    color: _glowColor,
                  ),
          ),
        ],
      ),
    );
  }
}
