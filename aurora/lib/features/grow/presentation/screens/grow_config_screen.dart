/// Grow Configuration Screen
/// Screen 2 of onboarding: Configure seed type, medium, lighting, and space.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/aurora_button.dart';

class GrowConfigScreen extends StatefulWidget {
  final String strainName;

  const GrowConfigScreen({
    super.key,
    required this.strainName,
  });

  @override
  State<GrowConfigScreen> createState() => _GrowConfigScreenState();
}

class _GrowConfigScreenState extends State<GrowConfigScreen> {
  String _seedType = 'feminized';
  String _medium = 'soil';
  String _lightType = 'LED';
  int _lightWattage = 300;
  int _spaceWidth = 60;
  int _spaceLength = 60;
  int _spaceHeight = 150;

  void _onContinue() {
    context.push(
      '/grow/start-date',
      extra: {
        'strainName': widget.strainName,
        'seedType': _seedType,
        'medium': _medium,
        'lightType': _lightType,
        'lightWattage': _lightWattage,
        'spaceWidth': _spaceWidth,
        'spaceLength': _spaceLength,
        'spaceHeight': _spaceHeight,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress
                      _buildProgress(),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'Configure Your Grow',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Growing ${widget.strainName}',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Seed Type
                      _buildSectionTitle('Seed Type'),
                      const SizedBox(height: 12),
                      _buildOptionRow(
                        options: ['Regular', 'Feminized', 'Auto'],
                        values: ['regular', 'feminized', 'auto'],
                        selected: _seedType,
                        onSelect: (v) => setState(() => _seedType = v),
                      ),
                      const SizedBox(height: 24),

                      // Growing Medium
                      _buildSectionTitle('Growing Medium'),
                      const SizedBox(height: 12),
                      _buildOptionRow(
                        options: ['Soil', 'Coco', 'Hydro', 'Aero'],
                        values: ['soil', 'coco', 'hydro', 'aero'],
                        selected: _medium,
                        onSelect: (v) => setState(() => _medium = v),
                      ),
                      const SizedBox(height: 24),

                      // Lighting
                      _buildSectionTitle('Lighting'),
                      const SizedBox(height: 12),
                      _buildOptionRow(
                        options: ['LED', 'HPS', 'CMH', 'CFL'],
                        values: ['LED', 'HPS', 'CMH', 'CFL'],
                        selected: _lightType,
                        onSelect: (v) => setState(() => _lightType = v),
                      ),
                      const SizedBox(height: 16),
                      _buildSlider(
                        label: 'Wattage',
                        value: _lightWattage.toDouble(),
                        min: 50,
                        max: 1000,
                        suffix: 'W',
                        onChanged: (v) =>
                            setState(() => _lightWattage = v.round()),
                      ),
                      const SizedBox(height: 24),

                      // Space Dimensions
                      _buildSectionTitle('Grow Space (cm)'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDimensionInput(
                              label: 'Width',
                              value: _spaceWidth,
                              onChanged: (v) =>
                                  setState(() => _spaceWidth = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDimensionInput(
                              label: 'Length',
                              value: _spaceLength,
                              onChanged: (v) =>
                                  setState(() => _spaceLength = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDimensionInput(
                              label: 'Height',
                              value: _spaceHeight,
                              onChanged: (v) =>
                                  setState(() => _spaceHeight = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Space visualization
                      _buildSpaceVisualization(),
                    ],
                  ),
                ),
              ),

              // Continue button
              Padding(
                padding: const EdgeInsets.all(24),
                child: AuroraButton(
                  text: 'Continue',
                  onPressed: _onContinue,
                  icon: Icons.arrow_forward,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Row(
      children: List.generate(5, (index) {
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: index <= 1
                  ? AppTheme.primary
                  : AppTheme.glassBackground,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildOptionRow({
    required List<String> options,
    required List<String> values,
    required String selected,
    required Function(String) onSelect,
  }) {
    return Row(
      children: List.generate(options.length, (index) {
        final isSelected = values[index] == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(values[index]),
            child: Container(
              margin: EdgeInsets.only(
                right: index < options.length - 1 ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.2)
                    : AppTheme.glassBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.glassBorder,
                ),
              ),
              child: Center(
                child: Text(
                  options[index],
                  style: TextStyle(
                    color:
                        isSelected ? AppTheme.primary : AppTheme.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required Function(double) onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.glassBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.round()}$suffix',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: AppTheme.glassBackground,
            thumbColor: AppTheme.primary,
            overlayColor: AppTheme.primary.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDimensionInput({
    required String label,
    required int value,
    required Function(int) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (value > 30) onChanged(value - 10);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value.toString(),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  if (value < 500) onChanged(value + 10);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceVisualization() {
    final aspectRatio = _spaceWidth / _spaceLength;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        children: [
          const Text(
            'Your Grow Space',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: aspectRatio.clamp(0.5, 2.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.3),
                    AppTheme.primary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.warning.withValues(alpha: 0.8),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_lightWattage W $_lightType',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_spaceWidth}cm × ${_spaceLength}cm × ${_spaceHeight}cm',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
