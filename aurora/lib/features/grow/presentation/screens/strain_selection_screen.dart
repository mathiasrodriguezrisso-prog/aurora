/// Strain Selection Screen
/// Screen 1 of onboarding: Search and select cannabis strain.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/aurora_button.dart';
import '../../../../shared/widgets/custom_input.dart';

/// Popular strains for quick selection.
const List<Map<String, String>> _popularStrains = [
  {'name': 'Northern Lights', 'type': 'Indica', 'difficulty': 'Easy'},
  {'name': 'Blue Dream', 'type': 'Hybrid', 'difficulty': 'Easy'},
  {'name': 'White Widow', 'type': 'Hybrid', 'difficulty': 'Easy'},
  {'name': 'Gorilla Glue #4', 'type': 'Hybrid', 'difficulty': 'Medium'},
  {'name': 'Girl Scout Cookies', 'type': 'Hybrid', 'difficulty': 'Medium'},
  {'name': 'OG Kush', 'type': 'Indica', 'difficulty': 'Medium'},
  {'name': 'Sour Diesel', 'type': 'Sativa', 'difficulty': 'Hard'},
  {'name': 'Jack Herer', 'type': 'Sativa', 'difficulty': 'Medium'},
];

class StrainSelectionScreen extends StatefulWidget {
  const StrainSelectionScreen({super.key});

  @override
  State<StrainSelectionScreen> createState() => _StrainSelectionScreenState();
}

class _StrainSelectionScreenState extends State<StrainSelectionScreen> {
  final _searchController = TextEditingController();
  String? _selectedStrain;
  String _searchQuery = '';

  List<Map<String, String>> get _filteredStrains {
    if (_searchQuery.isEmpty) return _popularStrains;
    return _popularStrains
        .where((s) =>
            s['name']!.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _onStrainSelected(String strain) {
    setState(() {
      _selectedStrain = strain;
    });
  }

  void _onContinue() {
    if (_selectedStrain != null) {
      context.push(
        '/grow/config',
        extra: {'strainName': _selectedStrain},
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 24),

                // Progress indicator
                _buildProgress(),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Choose Your Strain',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select the strain you\'ll be growing or enter a custom name',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Search field
                CustomInput(
                  controller: _searchController,
                  hint: 'Search strains...',
                  label: '',
                  prefixIcon: Icons.search,
                  onFieldSubmitted: (value) {
                    setState(() {
                      _searchQuery = value;
                      if (value.isNotEmpty && _filteredStrains.isEmpty) {
                        _selectedStrain = value;
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Use custom strain button
                if (_searchQuery.isNotEmpty && _filteredStrains.isEmpty)
                  _buildCustomStrainButton(),

                const SizedBox(height: 16),

                // Strain list
                Expanded(
                  child: _buildStrainList(),
                ),

                // Continue button
                const SizedBox(height: 16),
                AuroraButton(
                  text: 'Continue',
                  onPressed: _selectedStrain != null ? _onContinue : null,
                  icon: Icons.arrow_forward,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            // Skip to custom entry
            setState(() {
              _selectedStrain = 'Unknown Strain';
            });
            _onContinue();
          },
          child: const Text(
            'Skip',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      ],
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
              color: index == 0
                  ? AppTheme.primary
                  : AppTheme.glassBackground,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCustomStrainButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStrain = _searchQuery;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedStrain == _searchQuery
              ? AppTheme.primary.withValues(alpha: 0.2)
              : AppTheme.glassBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedStrain == _searchQuery
                ? AppTheme.primary
                : AppTheme.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline,
              color: _selectedStrain == _searchQuery
                  ? AppTheme.primary
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use "$_searchQuery"',
                    style: TextStyle(
                      color: _selectedStrain == _searchQuery
                          ? AppTheme.primary
                          : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Custom strain',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrainList() {
    final strains = _filteredStrains;

    if (strains.isEmpty && _searchQuery.isEmpty) {
      return const Center(
        child: Text(
          'No strains found',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: strains.length,
      itemBuilder: (context, index) {
        final strain = strains[index];
        final isSelected = _selectedStrain == strain['name'];

        return _StrainCard(
          name: strain['name']!,
          type: strain['type']!,
          difficulty: strain['difficulty']!,
          isSelected: isSelected,
          onTap: () => _onStrainSelected(strain['name']!),
        );
      },
    );
  }
}

class _StrainCard extends StatelessWidget {
  final String name;
  final String type;
  final String difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  const _StrainCard({
    required this.name,
    required this.type,
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  Color get _typeColor {
    switch (type.toLowerCase()) {
      case 'indica':
        return const Color(0xFF9B59B6);
      case 'sativa':
        return const Color(0xFFE74C3C);
      case 'hybrid':
        return AppTheme.primary;
      default:
        return AppTheme.textSecondary;
    }
  }

  Color get _difficultyColor {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppTheme.success;
      case 'medium':
        return AppTheme.warning;
      case 'hard':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            // Strain icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _typeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_florist,
                color: _typeColor,
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _typeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: _typeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _difficultyColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          difficulty,
                          style: TextStyle(
                            color: _difficultyColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Selection indicator
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
