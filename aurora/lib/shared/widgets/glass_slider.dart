/// Slider con estética glass y valor en vivo sobre el thumb.
library;

import 'package:flutter/material.dart';
import '../../../core/config/app_theme.dart';

class GlassSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String label;
  final String unit;
  final ValueChanged<double> onChanged;
  final Color? activeColor;

  const GlassSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.label,
    required this.unit,
    required this.onChanged,
    this.activeColor,
  });

  String get _formattedValue {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final color = activeColor ?? AppTheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$_formattedValue $unit',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: AppTheme.glassBackground,
            thumbColor: color,
            overlayColor: color.withValues(alpha: 0.15),
            trackHeight: 6,
            thumbShape: _GlowThumbShape(glowColor: color),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// Thumb con efecto glow neón.
class _GlowThumbShape extends SliderComponentShape {
  final Color glowColor;

  const _GlowThumbShape({required this.glowColor});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(20, 20);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Glow exterior
    canvas.drawCircle(
      center,
      12,
      Paint()
        ..color = glowColor.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Círculo sólido
    canvas.drawCircle(
      center,
      8,
      Paint()..color = glowColor,
    );

    // Punto interior
    canvas.drawCircle(
      center,
      3,
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );
  }
}
