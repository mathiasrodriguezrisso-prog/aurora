import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/config/app_theme.dart';

/// Diagnostic bottom sheet with basic grow data charts.
/// Shows temperature, humidity, and pH trends from grow snapshots.
class DiagnosticBottomSheet extends StatelessWidget {
  const DiagnosticBottomSheet({super.key});

  /// Show the diagnostic bottom sheet.
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DiagnosticBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Row(
                    children: [
                      Icon(
                        Icons.analytics_rounded,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Grow Diagnostics',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Temperature Chart
                  _ChartSection(
                    title: 'Temperature (°C)',
                    icon: Icons.thermostat_rounded,
                    color: AppTheme.warning,
                    spots: _temperatureData,
                    minY: 15,
                    maxY: 35,
                  ),
                  const SizedBox(height: 24),

                  // Humidity Chart
                  _ChartSection(
                    title: 'Humidity (%)',
                    icon: Icons.water_drop_rounded,
                    color: AppTheme.secondary,
                    spots: _humidityData,
                    minY: 20,
                    maxY: 80,
                  ),
                  const SizedBox(height: 24),

                  // pH Chart
                  _ChartSection(
                    title: 'pH Level',
                    icon: Icons.science_rounded,
                    color: AppTheme.primary,
                    spots: _phData,
                    minY: 5.0,
                    maxY: 7.5,
                  ),
                  const SizedBox(height: 16),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Charts show recent sensor readings. '
                            'Add grow snapshots to see real data.',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Demo data — replaced with real data when snapshots are available
  List<FlSpot> get _temperatureData => const [
        FlSpot(0, 24),
        FlSpot(1, 25),
        FlSpot(2, 26),
        FlSpot(3, 24.5),
        FlSpot(4, 25.5),
        FlSpot(5, 23),
        FlSpot(6, 25),
      ];

  List<FlSpot> get _humidityData => const [
        FlSpot(0, 55),
        FlSpot(1, 58),
        FlSpot(2, 60),
        FlSpot(3, 57),
        FlSpot(4, 52),
        FlSpot(5, 62),
        FlSpot(6, 59),
      ];

  List<FlSpot> get _phData => const [
        FlSpot(0, 6.2),
        FlSpot(1, 6.0),
        FlSpot(2, 6.3),
        FlSpot(3, 6.1),
        FlSpot(4, 6.4),
        FlSpot(5, 6.2),
        FlSpot(6, 6.0),
      ];
}

// ============================================
// Chart Section Widget
// ============================================

class _ChartSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<FlSpot> spots;
  final double minY;
  final double maxY;

  const _ChartSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.spots,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY - minY) / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withValues(alpha: 0.05),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: (maxY - minY) / 4,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(1),
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1,
                    getTitlesWidget: (value, meta) => Text(
                      'D${value.toInt() + 1}',
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: color,
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: color,
                      strokeWidth: 1,
                      strokeColor: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) =>
                      AppTheme.surface.withValues(alpha: 0.9),
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem(
                            s.y.toStringAsFixed(1),
                            TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
