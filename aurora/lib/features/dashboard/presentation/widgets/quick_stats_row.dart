/// 📁 lib/features/dashboard/presentation/widgets/quick_stats_row.dart
/// Row of 4 mini glass stat cards with animated numbers.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/config/app_theme.dart';

class QuickStatsRow extends StatelessWidget {
  final double? temperature;
  final double? humidity;
  final double? ph;
  final double? vpd;

  const QuickStatsRow({
    super.key,
    this.temperature,
    this.humidity,
    this.ph,
    this.vpd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.thermostat_rounded,
          label: 'Temp',
          value: temperature != null ? '${temperature!.toStringAsFixed(1)}°C' : '--',
          status: _getTempStatus(temperature),
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.water_drop_outlined,
          label: 'RH',
          value: humidity != null ? '${humidity!.toStringAsFixed(0)}%' : '--',
          status: _getHumidityStatus(humidity),
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.science_outlined,
          label: 'pH',
          value: ph != null ? ph!.toStringAsFixed(1) : '--',
          status: _getPhStatus(ph),
        ),
        const SizedBox(width: 8),
        _StatCard(
          icon: Icons.air_rounded,
          label: 'VPD',
          value: vpd != null ? vpd!.toStringAsFixed(2) : '--',
          status: _getVpdStatus(vpd),
        ),
      ],
    );
  }

  _StatStatus _getTempStatus(double? t) {
    if (t == null) return _StatStatus.unknown;
    if (t >= 20 && t <= 28) return _StatStatus.good;
    if (t >= 18 && t <= 30) return _StatStatus.warning;
    return _StatStatus.danger;
  }

  _StatStatus _getHumidityStatus(double? h) {
    if (h == null) return _StatStatus.unknown;
    if (h >= 40 && h <= 70) return _StatStatus.good;
    if (h >= 30 && h <= 80) return _StatStatus.warning;
    return _StatStatus.danger;
  }

  _StatStatus _getPhStatus(double? p) {
    if (p == null) return _StatStatus.unknown;
    if (p >= 5.8 && p <= 6.5) return _StatStatus.good;
    if (p >= 5.5 && p <= 7.0) return _StatStatus.warning;
    return _StatStatus.danger;
  }

  _StatStatus _getVpdStatus(double? v) {
    if (v == null) return _StatStatus.unknown;
    if (v >= 0.8 && v <= 1.2) return _StatStatus.good;
    if (v >= 0.4 && v <= 1.6) return _StatStatus.warning;
    return _StatStatus.danger;
  }
}

enum _StatStatus { good, warning, danger, unknown }

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final _StatStatus status;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
  });

  Color get _statusColor {
    switch (status) {
      case _StatStatus.good:
        return AppTheme.primary;
      case _StatStatus.warning:
        return AppTheme.warning;
      case _StatStatus.danger:
        return AppTheme.error;
      case _StatStatus.unknown:
        return AppTheme.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Column(
              children: [
                Icon(icon, size: 18, color: _statusColor),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textTertiary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                // Status dot
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
