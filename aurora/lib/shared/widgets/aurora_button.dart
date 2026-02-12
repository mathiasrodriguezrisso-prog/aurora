import 'package:flutter/material.dart';
import '../../core/config/app_theme.dart';

/// Primary button with neon glow effect.
class AuroraButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;

  const AuroraButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isOutlined || isDisabled ? [] : AppTheme.neonGlow,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined ? Colors.transparent : AppTheme.primary,
          foregroundColor: isOutlined ? AppTheme.primary : Colors.black,
          disabledBackgroundColor: isOutlined
              ? Colors.transparent
              : AppTheme.primary.withValues(alpha: 0.5),
          disabledForegroundColor: isOutlined
              ? AppTheme.primary.withValues(alpha: 0.5)
              : Colors.black.withValues(alpha: 0.5),
          shadowColor: Colors.transparent,
          side: isOutlined
              ? BorderSide(
                  color: isDisabled
                      ? AppTheme.primary.withValues(alpha: 0.5)
                      : AppTheme.primary,
                  width: 1.5,
                )
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: isOutlined ? AppTheme.primary : Colors.black,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
