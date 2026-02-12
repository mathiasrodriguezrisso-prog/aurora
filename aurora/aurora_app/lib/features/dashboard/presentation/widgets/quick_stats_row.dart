
import 'package:flutter/material.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/glass_container.dart';

class QuickStatsRow extends StatelessWidget {
  final Map<String, dynamic>? sensorData;

  const QuickStatsRow({super.key, required this.sensorData});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildCard("Temp", sensorData?['temperature'], Icons.thermostat, "°C", 20, 30)),
        const SizedBox(width: 8),
        Expanded(child: _buildCard("Humidity", sensorData?['humidity'], Icons.water_drop, "%", 40, 70)),
        const SizedBox(width: 8),
        Expanded(child: _buildCard("pH", sensorData?['ph'], Icons.science, "", 5.5, 6.5)),
        const SizedBox(width: 8),
        Expanded(child: _buildCard("EC", sensorData?['ec'], Icons.bolt, "mS", 1.0, 2.5)),
      ],
    );
  }

  Widget _buildCard(String label, dynamic value, IconData icon, String unit, double min, double max) {
    final valNum = value is num ? value.toDouble() : null;
    final isOptimal = valNum != null && valNum >= min && valNum <= max;
    final color = value == null ? Colors.white54 : (isOptimal ? AppTheme.primary : AppTheme.error);

    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      borderRadius: 12,
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value != null ? "$value$unit" : "--",
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }
}
