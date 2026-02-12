/// Gráfico de líneas de tendencia usando fl_chart.
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_theme.dart';
import '../../domain/entities/climate_current_entity.dart';
import '../../domain/entities/climate_reading_entity.dart';

class ClimateTrendChart extends StatelessWidget {
  final List<ClimateReadingEntity> readings;
  final ClimateIdealEntity? ideal;

  const ClimateTrendChart({
    super.key,
    required this.readings,
    this.ideal,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const Center(
        child: Text(
          'Registra datos para ver tendencias',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    // Ordenar por fecha por si acaso
    final sorted = List<ClimateReadingEntity>.from(readings)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Determinar rango de tiempo para formateo
    final first = sorted.first.createdAt;
    final last = sorted.last.createdAt;
    final diff = last.difference(first);
    final isDaily = diff.inHours <= 24;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: Colors.white10,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _calculateInterval(sorted.length),
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= sorted.length) return const SizedBox.shrink();
                final date = sorted[value.toInt()].createdAt;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    isDaily
                        ? DateFormat('HH:mm').format(date)
                        : DateFormat('d MMM').format(date),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (sorted.length - 1).toDouble(),
        minY: 0,
        maxY: 100, // Ajustado para incluir humedad (0-100%)
        lineBarsData: [
          // Temperatura (Rojo/Naranja)
          LineChartBarData(
            spots: sorted.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.temperature);
            }).toList(),
            isCurved: true,
            color: const Color(0xFFEF5350),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFEF5350).withValues(alpha: 0.1),
            ),
          ),
          // Humedad (Celeste) - Escanlar? No, 0-100 cabe en Y si ajustamos maxY
          // Pero temp es 20-30 y hum es 40-70. Mejor usar otro eje o normalizar.
          // Por simplicidad, graficamos todo en el mismo Y (0-100) y ajustamos maxY.
          // Humedad suele ser mas alta que temp.
          
          // Humedad
          LineChartBarData(
            spots: sorted.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.humidity);
            }).toList(),
            isCurved: true,
            color: const Color(0xFF4FC3F7),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF4FC3F7).withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index < 0 || index >= sorted.length) return null;
                final data = sorted[index];
                
                // Temp (rojo)
                if (spot.barIndex == 0) {
                   return LineTooltipItem(
                    '${data.temperature}°C',
                    const TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.bold),
                  );
                }
                // Hum (celeste)
                if (spot.barIndex == 1) {
                   return LineTooltipItem(
                    '${data.humidity}%',
                    const TextStyle(color: Color(0xFF4FC3F7), fontWeight: FontWeight.bold),
                  );
                }
                return null;
              }).toList();
            }
          ),
        ),
      ),
    );
  }

  double _calculateInterval(int length) {
    if (length <= 5) return 1;
    if (length <= 10) return 2;
    return (length / 5).floorToDouble();
  }
}
