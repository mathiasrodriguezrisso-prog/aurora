/// 📁 lib/features/grow/presentation/widgets/grow_timeline.dart
/// Timeline tab showing grow phases with visual phase indicators
/// and key events within each phase.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/config/app_theme.dart';

class GrowTimeline extends StatelessWidget {
  final Map<String, dynamic>? growPlan;

  const GrowTimeline({super.key, this.growPlan});

  @override
  Widget build(BuildContext context) {
    final phases = (growPlan?['phases'] as List<dynamic>?) ?? [];

    if (phases.isEmpty) {
      return const Center(
        child: Text(
          'No grow plan loaded yet.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
      itemCount: phases.length,
      itemBuilder: (context, index) {
        final phase = phases[index] as Map<String, dynamic>;
        final isActive =
            phase['status'] == 'active' || phase['status'] == 'current';
        final isCompleted = phase['status'] == 'completed';
        final isLast = index == phases.length - 1;
        final events = (phase['grow_events'] as List<dynamic>?) ?? [];

        return _PhaseCard(
          name: phase['name'] as String? ?? 'Phase ${index + 1}',
          description: phase['description'] as String? ?? '',
          durationDays: phase['duration_days'] as int? ?? 0,
          isActive: isActive,
          isCompleted: isCompleted,
          isLast: isLast,
          phaseIndex: index,
          events: events
              .map((e) => _TimelineEvent(
                    title: e['title'] as String? ?? '',
                    day: e['day_number'] as int? ?? 0,
                    type: e['event_type'] as String? ?? 'task',
                    isCompleted: e['is_completed'] as bool? ?? false,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _TimelineEvent {
  final String title;
  final int day;
  final String type;
  final bool isCompleted;

  const _TimelineEvent({
    required this.title,
    required this.day,
    required this.type,
    required this.isCompleted,
  });
}

class _PhaseCard extends StatelessWidget {
  final String name;
  final String description;
  final int durationDays;
  final bool isActive;
  final bool isCompleted;
  final bool isLast;
  final int phaseIndex;
  final List<_TimelineEvent> events;

  const _PhaseCard({
    required this.name,
    required this.description,
    required this.durationDays,
    required this.isActive,
    required this.isCompleted,
    required this.isLast,
    required this.phaseIndex,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? AppTheme.primary
                      : isCompleted
                          ? AppTheme.primary.withValues(alpha: 0.4)
                          : AppTheme.glassBackground,
                  border: Border.all(
                    color: isActive
                        ? AppTheme.primary
                        : isCompleted
                            ? AppTheme.primary.withValues(alpha: 0.5)
                            : AppTheme.glassBorder,
                    width: 2,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${phaseIndex + 1}',
                          style: TextStyle(
                            color: isActive
                                ? Colors.black
                                : AppTheme.textTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted
                        ? AppTheme.primary.withValues(alpha: 0.3)
                        : AppTheme.glassBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Phase content
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primary.withValues(alpha: 0.08)
                        : AppTheme.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? AppTheme.primary.withValues(alpha: 0.3)
                          : AppTheme.glassBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Phase header
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                color: isActive
                                    ? AppTheme.primary
                                    : AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppTheme.primary.withValues(alpha: 0.15)
                                  : AppTheme.glassBackground,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$durationDays days',
                              style: TextStyle(
                                color: isActive
                                    ? AppTheme.primary
                                    : AppTheme.textTertiary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],

                      // Events
                      if (events.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ...events.take(4).map((event) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    event.isCompleted
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    size: 16,
                                    color: event.isCompleted
                                        ? AppTheme.primary
                                        : AppTheme.textTertiary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      event.title,
                                      style: TextStyle(
                                        color: event.isCompleted
                                            ? AppTheme.textTertiary
                                            : AppTheme.textSecondary,
                                        fontSize: 12,
                                        decoration: event.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Day ${event.day}',
                                    style: const TextStyle(
                                      color: AppTheme.textTertiary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        if (events.length > 4)
                          Text(
                            '+${events.length - 4} more events',
                            style: TextStyle(
                              color: AppTheme.primary.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
