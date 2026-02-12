/// Barra de progreso para wizard multi-paso con dots animados y gradiente neón.
library;

import 'package:flutter/material.dart';
import '../../../core/config/app_theme.dart';

class WizardProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? stepLabels;

  const WizardProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSteps > 1
        ? currentStep / (totalSteps - 1)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra horizontal con gradiente
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.glassBackground,
              borderRadius: BorderRadius.circular(2),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Progreso animado
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      width: constraints.maxWidth * progress,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, Color(0xFF00BFFF)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              return _StepDot(
                key: ValueKey('step_dot_$index'),
                stepIndex: index,
                currentStep: currentStep,
                label: stepLabels != null && index < stepLabels!.length
                    ? stepLabels![index]
                    : null,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int stepIndex;
  final int currentStep;
  final String? label;

  const _StepDot({
    super.key,
    required this.stepIndex,
    required this.currentStep,
    this.label,
  });

  bool get _isCompleted => stepIndex < currentStep;
  bool get _isCurrent => stepIndex == currentStep;
  bool get _isFuture => stepIndex > currentStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isCurrent ? 28 : 20,
          height: _isCurrent ? 28 : 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isCompleted || _isCurrent
                ? AppTheme.primary
                : Colors.transparent,
            border: Border.all(
              color: _isFuture
                  ? AppTheme.textTertiary
                  : AppTheme.primary,
              width: 2,
            ),
            boxShadow: _isCurrent
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: _isCompleted
                ? const Icon(Icons.check, color: Colors.black, size: 12)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      color: _isCurrent ? Colors.black : AppTheme.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: 50,
            child: Text(
              label!,
              style: TextStyle(
                color: _isFuture ? AppTheme.textTertiary : AppTheme.textSecondary,
                fontSize: 9,
                fontWeight: _isCurrent ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
