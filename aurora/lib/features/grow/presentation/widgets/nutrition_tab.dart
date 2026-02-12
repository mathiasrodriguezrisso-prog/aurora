/// 📁 lib/features/grow/presentation/widgets/nutrition_tab.dart
/// Nutrition tab showing feeding schedules, deficiency alerts,
/// and nutrient recommendations for the current phase.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/config/app_theme.dart';

class NutritionTab extends StatelessWidget {
  final Map<String, dynamic>? growPlan;
  final String growId;
  final String currentPhase;

  const NutritionTab({
    super.key,
    this.growPlan,
    required this.growId,
    required this.currentPhase,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Phase Nutrients
          _buildSectionLabel('Nutrition for: $currentPhase'),
          const SizedBox(height: 8),
          _buildNutrientCard(),
          const SizedBox(height: 24),

          // NPK Ratios
          _buildSectionLabel('Recommended NPK Ratio'),
          const SizedBox(height: 8),
          _buildNpkChart(),
          const SizedBox(height: 24),

          // Feeding Schedule
          _buildSectionLabel('Feeding Schedule'),
          const SizedBox(height: 8),
          _buildFeedingSchedule(),
          const SizedBox(height: 24),

          // Deficiency Guide
          _buildSectionLabel('Common Deficiency Indicators'),
          const SizedBox(height: 8),
          _buildDeficiencyGuide(),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildNutrientCard() {
    // Derive nutrients from the current phase plan
    final phases = (growPlan?['phases'] as List<dynamic>?) ?? [];
    Map<String, dynamic>? currentPhaseData;
    for (final p in phases) {
      final name = p['name'] as String? ?? '';
      if (name.toLowerCase() == currentPhase.toLowerCase() ||
          p['status'] == 'active' ||
          p['status'] == 'current') {
        currentPhaseData = p as Map<String, dynamic>;
        break;
      }
    }

    final nutrients = currentPhaseData?['nutrients'] as Map<String, dynamic>?;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Column(
            children: [
              _NutrientRow(
                label: 'Nitrogen (N)',
                level: nutrients?['nitrogen'] as String? ?? 'Medium',
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              _NutrientRow(
                label: 'Phosphorus (P)',
                level: nutrients?['phosphorus'] as String? ?? 'Low',
                color: Colors.orange,
              ),
              const SizedBox(height: 8),
              _NutrientRow(
                label: 'Potassium (K)',
                level: nutrients?['potassium'] as String? ?? 'Medium',
                color: Colors.blue,
              ),
              const SizedBox(height: 8),
              _NutrientRow(
                label: 'Calcium (Ca)',
                level: nutrients?['calcium'] as String? ?? 'Medium',
                color: Colors.purple,
              ),
              const SizedBox(height: 8),
              _NutrientRow(
                label: 'Magnesium (Mg)',
                level: nutrients?['magnesium'] as String? ?? 'Low',
                color: Colors.teal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNpkChart() {
    // NPK ratios based on phase
    double n, p, k;
    switch (currentPhase.toLowerCase()) {
      case 'seedling':
      case 'germination':
        n = 1;
        p = 1;
        k = 1;
      case 'vegetative':
      case 'veg':
        n = 3;
        p = 1;
        k = 2;
      case 'flowering':
      case 'bloom':
        n = 1;
        p = 3;
        k = 2;
      case 'ripening':
      case 'flush':
        n = 0;
        p = 0;
        k = 0;
      default:
        n = 2;
        p = 1;
        k = 2;
    }

    final total = n + p + k;
    if (total == 0) {
      return _buildGlassCard(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Plain water — no nutrients during flush',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ),
      );
    }

    return _buildGlassCard(
      child: Row(
        children: [
          _NpkBar(label: 'N', value: n, maxValue: total, color: Colors.green),
          const SizedBox(width: 16),
          _NpkBar(label: 'P', value: p, maxValue: total, color: Colors.orange),
          const SizedBox(width: 16),
          _NpkBar(label: 'K', value: k, maxValue: total, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildFeedingSchedule() {
    return _buildGlassCard(
      child: Column(
        children: [
          _FeedRow(
            icon: Icons.water_drop_outlined,
            title: 'Water',
            frequency: 'Every 2-3 days',
            notes: 'pH 6.0-6.5',
          ),
          const Divider(color: AppTheme.glassBorder, height: 16),
          _FeedRow(
            icon: Icons.science_outlined,
            title: 'Base Nutrients',
            frequency: 'Every watering',
            notes: '50-75% recommended dose',
          ),
          const Divider(color: AppTheme.glassBorder, height: 16),
          _FeedRow(
            icon: Icons.local_florist_outlined,
            title: 'Cal-Mag',
            frequency: 'Every other watering',
            notes: '2-3 ml/L',
          ),
        ],
      ),
    );
  }

  Widget _buildDeficiencyGuide() {
    return Column(
      children: [
        _DeficiencyCard(
          nutrient: 'Nitrogen',
          symptom: 'Lower leaves yellowing from tips',
          icon: Icons.warning_amber_rounded,
          color: Colors.yellow,
        ),
        const SizedBox(height: 8),
        _DeficiencyCard(
          nutrient: 'Phosphorus',
          symptom: 'Purple/dark stems, slow growth',
          icon: Icons.warning_amber_rounded,
          color: Colors.purple,
        ),
        const SizedBox(height: 8),
        _DeficiencyCard(
          nutrient: 'Potassium',
          symptom: 'Brown edges on leaves',
          icon: Icons.warning_amber_rounded,
          color: Colors.brown,
        ),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Private Widgets
// ─────────────────────────────────────────────────────

class _NutrientRow extends StatelessWidget {
  final String label;
  final String level;
  final Color color;

  const _NutrientRow({
    required this.label,
    required this.level,
    required this.color,
  });

  double get _levelValue {
    switch (level.toLowerCase()) {
      case 'high':
        return 1.0;
      case 'medium':
        return 0.6;
      case 'low':
        return 0.3;
      default:
        return 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _levelValue,
              backgroundColor: AppTheme.glassBackground,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 50,
          child: Text(
            level,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _NpkBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;

  const _NpkBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.glassBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                height: 80 * (value / maxValue),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toInt()}',
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

class _FeedRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String frequency;
  final String notes;

  const _FeedRow({
    required this.icon,
    required this.title,
    required this.frequency,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$frequency • $notes',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeficiencyCard extends StatelessWidget {
  final String nutrient;
  final String symptom;
  final IconData icon;
  final Color color;

  const _DeficiencyCard({
    required this.nutrient,
    required this.symptom,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$nutrient Deficiency',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  symptom,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
