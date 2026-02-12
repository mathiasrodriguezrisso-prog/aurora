/// Widget interactivo de mapa de calor VPD.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../core/utils/vpd_calculator.dart';

class VPDHeatmap extends StatefulWidget {
  final double? currentTemp;
  final double? currentHumidity;
  final String phase;

  const VPDHeatmap({
    super.key,
    required this.phase,
    this.currentTemp,
    this.currentHumidity,
  });

  @override
  State<VPDHeatmap> createState() => _VPDHeatmapState();
}

class _VPDHeatmapState extends State<VPDHeatmap>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Offset? _touchPosition;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mapa VPD',
              style: AppTheme.darkTheme.textTheme.titleMedium,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.glassBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Text(
                'Fase: ${widget.phase}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Heatmap
        AspectRatio(
          aspectRatio: 1.3,
          child: GestureDetector(
            onTapDown: (details) {
              setState(() => _touchPosition = details.localPosition);
            },
            onTapUp: (_) {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) setState(() => _touchPosition = null);
              });
            },
            onPanUpdate: (details) {
              setState(() => _touchPosition = details.localPosition);
            },
            onPanEnd: (_) {
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) setState(() => _touchPosition = null);
              });
            },
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _VPDHeatmapPainter(
                    currentTemp: widget.currentTemp,
                    currentHumidity: widget.currentHumidity,
                    phase: widget.phase,
                    pulseValue: _pulseController.value,
                    touchPosition: _touchPosition,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Legend
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _LegendItem(color: const Color(0xFF2196F3), label: '<0.4'),
        _LegendItem(color: const Color(0xFF4FC3F7), label: '0.4-0.8'),
        _LegendItem(color: const Color(0xFF00FF88), label: '0.8-1.2'),
        _LegendItem(color: const Color(0xFFFFA726), label: '1.2-1.6'),
        _LegendItem(color: const Color(0xFFEF5350), label: '>1.6'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        ),
      ],
    );
  }
}

class _VPDHeatmapPainter extends CustomPainter {
  final double? currentTemp;
  final double? currentHumidity;
  final String phase;
  final double pulseValue;
  final Offset? touchPosition;

  _VPDHeatmapPainter({
    this.currentTemp,
    this.currentHumidity,
    required this.phase,
    required this.pulseValue,
    this.touchPosition,
  });

  // Constantes de visualización
  static const double tempMin = 15;
  static const double tempMax = 35;
  static const double humMin = 30;
  static const double humMax = 90;

  @override
  void paint(Canvas canvas, Size size) {
    const double leftMargin = 40;
    const double bottomMargin = 30;
    const double topMargin = 10;
    const double rightMargin = 10;

    final chartRect = Rect.fromLTRB(
      leftMargin,
      topMargin,
      size.width - rightMargin,
      size.height - bottomMargin,
    );

    // 1. Dibujar celdas del heatmap
    const int cols = 21; // 15 a 35 = 21 pasos (step 1)
    const int rows = 13; // 30 a 90 = 60 rango / 5 step = 12 rangos + 1 = 13 puntos?
    // Mejor usaremos steps fijos para celdas rectangulares.
    // Temp: 15, 16, ..., 35 (20 intervalos de 1 grado)
    // Hum: 30, 35, ..., 90 (12 intervalos de 5%)

    final cellWidth = chartRect.width / 20;
    final cellHeight = chartRect.height / 12;

    for (int col = 0; col < 20; col++) {
      for (int row = 0; row < 12; row++) {
        // Temp centro de celda
        final temp = tempMin + col;
        // Hum centro de celda (invertido: 90 arriba, 30 abajo)
        // row 0 es arriba (90%), row 11 es abajo (35%)
        // Queremos dibujar desde arriba hacia abajo.
        // row 0 -> hum 90
        final hum = humMax - (row * 5); // 90, 85...

        final vpd = VPDCalculator.calculateVPD(temp.toDouble(), hum.toDouble());
        final color = VPDCalculator.getVPDColor(vpd);

        final cellRect = Rect.fromLTWH(
          chartRect.left + (col * cellWidth),
          chartRect.top + (row * cellHeight),
          cellWidth + 0.5, // solapamiento ligero para evitar líneas blancas
          cellHeight + 0.5,
        );

        canvas.drawRect(cellRect, Paint()..color = color);
      }
    }

    // 2. Labels Eje X (Temperatura)
    final textStyle = const TextStyle(color: Colors.white70, fontSize: 10);
    // 15, 20, 25, 30, 35
    for (int t = 15; t <= 35; t += 5) {
      final xPct = (t - tempMin) / (tempMax - tempMin);
      final x = chartRect.left + (xPct * chartRect.width);

      final span = TextSpan(style: textStyle, text: '$t°');
      final tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x - (tp.width / 2), size.height - 20));
    }

    // 3. Labels Eje Y (Humedad)
    // 30, 40, ..., 90
    for (int h = 30; h <= 90; h += 10) {
      final yPct = (humMax - h) / (humMax - humMin);
      final y = chartRect.top + (yPct * chartRect.height);

      final span = TextSpan(style: textStyle, text: '$h%');
      final tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(5, y - (tp.height / 2)));
    }

    // Labels títulos de ejes
    final axisTitleStyle = const TextStyle(color: Colors.white30, fontSize: 10);
    final tempTitle = TextPainter(
      text: TextSpan(style: axisTitleStyle, text: 'Temp (°C)'),
      textDirection: TextDirection.ltr,
    );
    tempTitle.layout();
    tempTitle.paint(canvas, Offset(size.width - 60, size.height - 10));

    final humTitle = TextPainter(
      text: TextSpan(style: axisTitleStyle, text: 'Hum (%)'),
      textDirection: TextDirection.ltr,
    );
    humTitle.layout();
    humTitle.paint(canvas, Offset(5, 0));

    // 4. Punto actual
    if (currentTemp != null &&
        currentHumidity != null &&
        currentTemp! >= tempMin &&
        currentTemp! <= tempMax &&
        currentHumidity! >= humMin &&
        currentHumidity! <= humMax) {
      final xPct = (currentTemp! - tempMin) / (tempMax - tempMin);
      final yPct = (humMax - currentHumidity!) / (humMax - humMin);

      final x = chartRect.left + (xPct * chartRect.width);
      final y = chartRect.top + (yPct * chartRect.height);

      // Glow pulsante
      final glowRadius = 6 + (pulseValue * 6); // 6 a 12
      canvas.drawCircle(
        Offset(x, y),
        glowRadius,
        Paint()
          ..color = Colors.white.withOpacity(0.4 * (1 - pulseValue))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Punto sólido
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.white);
      canvas.drawCircle(
          Offset(x, y), 3, Paint()..color = AppTheme.primary);
    }

    // 5. Tooltip al tocar
    if (touchPosition != null && chartRect.contains(touchPosition!)) {
      final dx = touchPosition!.dx - chartRect.left;
      final dy = touchPosition!.dy - chartRect.top;

      // Invertir coordenadas para obtener valores
      final tempVal = tempMin + ((dx / chartRect.width) * (tempMax - tempMin));
      final humVal = humMax - ((dy / chartRect.height) * (humMax - humMin));

      final vpd = VPDCalculator.calculateVPD(tempVal, humVal);
      final zone = VPDCalculator.getVPDZone(vpd, phase);

      final text =
          'T: ${tempVal.toStringAsFixed(1)}°  H: ${humVal.toStringAsFixed(0)}%\nVPD: $vpd kPa (${zone.label})';

      final span = TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        text: text,
      );
      final tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tp.layout();

      // Dibujar fondo tooltip
      final tooltipW = tp.width + 16;
      final tooltipH = tp.height + 16;
      var tooltipX = touchPosition!.dx - (tooltipW / 2);
      var tooltipY = touchPosition!.dy - tooltipH - 10;

      // Ajustes bordes
      if (tooltipX < 0) tooltipX = 10;
      if (tooltipX + tooltipW > size.width) tooltipX = size.width - tooltipW - 10;
      if (tooltipY < 0) tooltipY = touchPosition!.dy + 20;

      final tooltipRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(tooltipX, tooltipY, tooltipW, tooltipH),
        const Radius.circular(8),
      );

      canvas.drawRRect(
        tooltipRect,
        Paint()..color = Colors.black.withOpacity(0.8),
      );
      canvas.drawRRect(
        tooltipRect,
        Paint()
          ..color = zone.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );

      tp.paint(canvas, Offset(tooltipX + 8, tooltipY + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _VPDHeatmapPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.currentTemp != currentTemp ||
        oldDelegate.currentHumidity != currentHumidity ||
        oldDelegate.touchPosition != touchPosition;
  }
}
