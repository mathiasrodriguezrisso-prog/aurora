/// Plant Status Widget
/// Visual indicator of overall plant health and environmental parameters.
library;

import 'package:flutter/material.dart';
import '../../../../core/config/app_theme.dart';

class PlantStatusWidget extends StatelessWidget {
  final double vpd;
  final double temperature;
  final double humidity;
  final String healthStatus; // 'excellent', 'good', 'fair', 'poor'

  const PlantStatusWidget({
    super.key,
    required this.vpd,
    required this.temperature,
    required this.humidity,
    required this.healthStatus,
  });

  Color get _statusColor {
    switch (healthStatus.toLowerCase()) {
      case 'excellent':
        return AppTheme.success;
      case 'good':
        return AppTheme.primary;
      case 'fair':
        return AppTheme.warning;
      case 'poor':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PLANT STATUS',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  healthStatus.toUpperCase(),
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ParameterColumn(
                label: 'VPD',
                value: vpd.toStringAsFixed(1),
                unit: 'kPa',
                icon: Icons.cloud_queue,
              ),
              _ParameterColumn(
                label: 'TEMP',
                value: temperature.toStringAsFixed(1),
                unit: '°C',
                icon: Icons.thermostat,
              ),
              _ParameterColumn(
                label: 'RH',
                value: humidity.toStringAsFixed(0),
                unit: '%',
                icon: Icons.water_drop,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParameterColumn extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _ParameterColumn({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.textSecondary, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
