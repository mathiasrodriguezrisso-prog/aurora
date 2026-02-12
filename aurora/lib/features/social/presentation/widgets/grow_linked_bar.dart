/// Barra Grow-Linked que aparece sobre las imágenes en los posts.
/// Muestra datos del grow snapshot (cepa, semana, fase, sensor data).
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/config/app_theme.dart';
import '../../domain/entities/grow_snapshot_entity.dart';

class GrowLinkedBar extends StatefulWidget {
  final GrowSnapshotEntity snapshot;

  const GrowLinkedBar({super.key, required this.snapshot});

  @override
  State<GrowLinkedBar> createState() => _GrowLinkedBarState();
}

class _GrowLinkedBarState extends State<GrowLinkedBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            color: Colors.black.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Collapsed row: strain + week + phase
                Row(
                  children: [
                    const Text('🌿', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${widget.snapshot.strain} • Week ${widget.snapshot.week} • ${widget.snapshot.phase}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ),

                // Expanded details: sensor data
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _sensorChip(
                        icon: Icons.thermostat_outlined,
                        label: '${widget.snapshot.temperature.toStringAsFixed(1)}°C',
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 8),
                      _sensorChip(
                        icon: Icons.water_drop_outlined,
                        label: '${widget.snapshot.humidity.toStringAsFixed(0)}%',
                        color: AppTheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      _sensorChip(
                        icon: Icons.speed_outlined,
                        label: 'VPD ${widget.snapshot.vpd.toStringAsFixed(2)}',
                        color: AppTheme.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _tagChip('🪴 ${widget.snapshot.medium}'),
                      const SizedBox(width: 8),
                      _tagChip('💡 ${widget.snapshot.lightType}'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sensorChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
