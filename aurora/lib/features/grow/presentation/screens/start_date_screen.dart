/// Start Date Screen
/// Screen 3 of onboarding: Set start date and experience level.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/aurora_button.dart';

class StartDateScreen extends StatefulWidget {
  final Map<String, dynamic> growConfig;

  const StartDateScreen({
    super.key,
    required this.growConfig,
  });

  @override
  State<StartDateScreen> createState() => _StartDateScreenState();
}

class _StartDateScreenState extends State<StartDateScreen> {
  DateTime _startDate = DateTime.now();
  String _experienceLevel = 'beginner';

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.black,
              surface: AppTheme.backgroundGradientEnd,
              onSurface: AppTheme.textPrimary,
            ),
            dialogBackgroundColor: AppTheme.background,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  void _onContinue() {
    context.push(
      '/grow/generating',
      extra: {
        ...widget.growConfig,
        'startDate': _startDate.toIso8601String(),
        'experienceLevel': _experienceLevel,
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

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress
                      _buildProgress(),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'When Do You Start?',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tell us when your grow begins and your experience level',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Date Picker
                      _buildDatePicker(),
                      const SizedBox(height: 32),

                      // Experience Level
                      const Text(
                        'EXPERIENCE LEVEL',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildExperienceSelector(),

                      const Spacer(),

                      // Summary
                      _buildSummary(),
                    ],
                  ),
                ),
              ),

              // Continue button
              Padding(
                padding: const EdgeInsets.all(24),
                child: AuroraButton(
                  text: 'Generate My Plan',
                  onPressed: _onContinue,
                  icon: Icons.auto_awesome,
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
              color: index <= 2
                  ? AppTheme.primary
                  : AppTheme.glassBackground,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDatePicker() {
    final isToday = _startDate.day == DateTime.now().day &&
        _startDate.month == DateTime.now().month &&
        _startDate.year == DateTime.now().year;

    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today,
              color: AppTheme.primary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              isToday ? 'Today' : _formatDate(_startDate),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatFullDate(_startDate),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Tap to change',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceSelector() {
    return Column(
      children: [
        _ExperienceOption(
          title: 'Beginner',
          description: 'First grow or still learning the basics',
          icon: Icons.spa_outlined,
          isSelected: _experienceLevel == 'beginner',
          onTap: () => setState(() => _experienceLevel = 'beginner'),
        ),
        const SizedBox(height: 12),
        _ExperienceOption(
          title: 'Intermediate',
          description: 'A few grows under my belt',
          icon: Icons.local_florist_outlined,
          isSelected: _experienceLevel == 'intermediate',
          onTap: () => setState(() => _experienceLevel = 'intermediate'),
        ),
        const SizedBox(height: 12),
        _ExperienceOption(
          title: 'Advanced',
          description: 'Experienced grower, ready for optimization',
          icon: Icons.eco_outlined,
          isSelected: _experienceLevel == 'advanced',
          onTap: () => setState(() => _experienceLevel = 'advanced'),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final config = widget.growConfig;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.summarize_outlined,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config['strainName'] ?? 'Unknown',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${config['seedType']} • ${config['medium']} • ${config['lightType']} ${config['lightWattage']}W',
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatFullDate(DateTime date) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _ExperienceOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExperienceOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.glassBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.glassBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.2)
                    : AppTheme.glassBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color:
                          isSelected ? AppTheme.primary : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.black,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
