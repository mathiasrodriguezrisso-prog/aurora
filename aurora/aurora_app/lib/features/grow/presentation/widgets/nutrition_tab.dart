
import 'package:flutter/material.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/glass_container.dart';

class NutritionTab extends StatelessWidget {
  final Map<String, dynamic> growData;

  const NutritionTab({super.key, required this.growData});

  @override
  Widget build(BuildContext context) {
    // Mock logic for MVP: check if there's a structure for nutrients in the plan
    // In a real scenario, we'd parse this from growData['configuration']['plan']['phases'][currentPhaseIndex]['nutrients']
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Current Phase Nutrition", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 12),
                Text("Follow your nutrient brand's feeding chart for the current phase.", style: TextStyle(color: Colors.white70)),
                SizedBox(height: 4),
                Text("Adjust based on plant response.", style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          GlassContainer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTarget("EC Target", "1.2 - 1.8"),
                _buildTarget("pH Target", "5.8 - 6.2"),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const GlassContainer(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Text("Feeding Log", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Text("Coming soon - log your feedings here", style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarget(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }
}
