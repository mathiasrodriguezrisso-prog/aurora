/// Plan Summary Screen
/// Screen 5 of onboarding: Display generated plan with visual timeline.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/aurora_button.dart';
import '../../domain/entities/grow_plan_entity.dart';

class PlanSummaryScreen extends StatefulWidget {
  final GrowPlanEntity plan;
  final Map<String, dynamic> config;

  const PlanSummaryScreen({
    super.key,
    required this.plan,
    required this.config,
  });

  @override
  State<PlanSummaryScreen> createState() => _PlanSummaryScreenState();
}

class _PlanSummaryScreenState extends State<PlanSummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedPhaseIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _startGrow() {
    // Navigate to home/dashboard, clearing the stack
    context.go('/home');
  }

  Color _getPhaseColor(String phase) {
    switch (phase.toLowerCase()) {
      case 'germination':
        return const Color(0xFF8B4513);
      case 'seedling':
        return const Color(0xFF90EE90);
      case 'vegetative':
        return AppTheme.primary;
      case 'flowering':
        return const Color(0xFFFF69B4);
      case 'harvest':
        return AppTheme.warning;
      case 'drying':
        return const Color(0xFFDEB887);
      case 'curing':
        return const Color(0xFFCD853F);
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
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
                        // Progress complete
                        _buildProgress(),
                        const SizedBox(height: 24),

                        // Success message
                        _buildSuccessCard(),
                        const SizedBox(height: 24),

                        // Summary stats
                        _buildSummaryStats(plan),
                        const SizedBox(height: 24),

                        // Timeline
                        const Text(
                          'YOUR GROW TIMELINE',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTimeline(plan),
                        const SizedBox(height: 24),

                        // Phase details
                        if (plan.phases.isNotEmpty)
                          _buildPhaseDetails(plan.phases[_selectedPhaseIndex]),
                        const SizedBox(height: 24),

                        // Key tips
                        _buildKeyTips(plan),
                      ],
                    ),
                  ),
                ),

                // Start button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: AuroraButton(
                    text: 'Start My Grow',
                    onPressed: _startGrow,
                    icon: Icons.rocket_launch,
                  ),
                ),
              ],
            ),
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
          const Spacer(),
          IconButton(
            onPressed: () {
              // TODO: Share plan
            },
            icon: const Icon(Icons.share_outlined, color: AppTheme.textSecondary),
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
              color: AppTheme.primary,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.2),
            AppTheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
              boxShadow: AppTheme.neonGlow,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.black,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your Plan is Ready!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.plan.strainName} grow plan created',
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(GrowPlanEntity plan) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_today,
            value: '${plan.summary.totalDurationDays}',
            label: 'Days',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.speed,
            value: '${plan.summary.estimatedYieldMin}-${plan.summary.estimatedYieldMax}',
            label: 'Grams Est.',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.star,
            value: '${plan.summary.difficultyRating}/5',
            label: 'Difficulty',
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(GrowPlanEntity plan) {
    final totalDays = plan.summary.totalDurationDays.toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        children: [
          // Visual timeline bar
          SizedBox(
            height: 48,
            child: Row(
              children: plan.phases.asMap().entries.map((entry) {
                final index = entry.key;
                final phase = entry.value;
                final width = (phase.durationDays / totalDays).clamp(0.05, 1.0);
                final isSelected = index == _selectedPhaseIndex;

                return Expanded(
                  flex: (width * 100).round(),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPhaseIndex = index),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < plan.phases.length - 1 ? 2 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: _getPhaseColor(phase.phase).withValues(
                          alpha: isSelected ? 1.0 : 0.5,
                        ),
                        borderRadius: BorderRadius.horizontal(
                          left: index == 0 ? const Radius.circular(8) : Radius.zero,
                          right: index == plan.phases.length - 1
                              ? const Radius.circular(8)
                              : Radius.zero,
                        ),
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Phase labels
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: plan.phases.asMap().entries.map((entry) {
                final index = entry.key;
                final phase = entry.value;
                final isSelected = index == _selectedPhaseIndex;

                return GestureDetector(
                  onTap: () => setState(() => _selectedPhaseIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getPhaseColor(phase.phase).withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? _getPhaseColor(phase.phase)
                            : AppTheme.glassBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getPhaseColor(phase.phase),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          phase.name,
                          style: TextStyle(
                            color: isSelected
                                ? _getPhaseColor(phase.phase)
                                : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseDetails(GrowPlanPhase phase) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getPhaseColor(phase.phase).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getPhaseColor(phase.phase).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getPhaseIcon(phase.phase),
                  color: _getPhaseColor(phase.phase),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phase.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Days ${phase.startDay} - ${phase.endDay} (${phase.durationDays} days)',
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
          const SizedBox(height: 16),
          Text(
            phase.description,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Environment quick view
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.thermostat,
                label: '${phase.environment.temperatureDayC}°C',
              ),
              _InfoChip(
                icon: Icons.water_drop,
                label: '${phase.environment.humidityPercent}%',
              ),
              _InfoChip(
                icon: Icons.light_mode,
                label: '${phase.environment.lightHours}h',
              ),
              _InfoChip(
                icon: Icons.science,
                label: 'EC ${phase.nutrients.ecMin}-${phase.nutrients.ecMax}',
              ),
            ],
          ),

          // Key milestones
          if (phase.keyMilestones.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Key Milestones',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...phase.keyMilestones.take(3).map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 14,
                        color: _getPhaseColor(phase.phase),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildKeyTips(GrowPlanEntity plan) {
    if (plan.summary.keySuccessFactors.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KEY SUCCESS FACTORS',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ...plan.summary.keySuccessFactors.take(4).map((tip) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.glassBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  IconData _getPhaseIcon(String phase) {
    switch (phase.toLowerCase()) {
      case 'germination':
        return Icons.grain;
      case 'seedling':
        return Icons.spa;
      case 'vegetative':
        return Icons.grass;
      case 'flowering':
        return Icons.local_florist;
      case 'harvest':
        return Icons.content_cut;
      case 'drying':
        return Icons.air;
      case 'curing':
        return Icons.inventory_2;
      default:
        return Icons.eco;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
