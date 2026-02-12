
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_theme.dart';

class GrowConfigScreen extends StatefulWidget {
  final Map<String, dynamic> extra;
  const GrowConfigScreen({super.key, required this.extra});

  @override
  State<GrowConfigScreen> createState() => _GrowConfigScreenState();
}

class _GrowConfigScreenState extends State<GrowConfigScreen> {
  String _seedType = 'Feminized';
  String _medium = 'Soil';
  String _lightType = 'LED';
  double _watts = 400;
  double _space = 1.0;

  @override
  Widget build(BuildContext context) {
    // Config from previous screen (strain name)
    // We treat 'extra' as containing the strain 
    final extraMap = widget.extra;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text("Configure Your Grow")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seed Type
            const Text("Seed Type", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Feminized', 'Regular', 'Autoflower', 'Clone'].map((type) {
                final isSelected = _seedType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (s) => setState(() => _seedType = type),
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surface,
                  labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                  side: isSelected ? BorderSide.none : const BorderSide(color: Colors.white24),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Growing Medium
            const Text("Growing Medium", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Soil', 'Coco', 'Hydro', 'Aero'].map((type) {
                final isSelected = _medium == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (s) => setState(() => _medium = type),
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surface,
                  labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                  side: isSelected ? BorderSide.none : const BorderSide(color: Colors.white24),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Light Type
            const Text("Light Type", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['LED', 'HPS', 'CMH'].map((type) {
                final isSelected = _lightType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (s) => setState(() => _lightType = type),
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surface,
                  labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                  side: isSelected ? BorderSide.none : const BorderSide(color: Colors.white24),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Light Power
            Text("Light Power: ${_watts.round()}W", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Slider(
              value: _watts,
              min: 100,
              max: 1200,
              divisions: 22,
              activeColor: AppTheme.primary,
              inactiveColor: Colors.white10,
              onChanged: (val) => setState(() => _watts = val),
            ),

            const SizedBox(height: 24),

            // Grow Space
            Text("Grow Space: ${_space.toStringAsFixed(1)} m²", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Slider(
              value: _space,
              min: 0.5,
              max: 10.0,
              divisions: 19, // (10-0.5)/0.5 = 19 steps
              activeColor: AppTheme.primary,
              inactiveColor: Colors.white10,
              onChanged: (val) => setState(() => _space = val),
            ),

            const SizedBox(height: 32),

            // Next Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  context.push('/grow/start-date', extra: {
                    ...extraMap,
                    'seed_type': _seedType,
                    'medium': _medium,
                    'light_type': _lightType,
                    'watts': _watts.round(),
                    'space': _space,
                  });
                },
                child: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
