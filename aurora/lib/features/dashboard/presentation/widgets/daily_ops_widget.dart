/// Daily Ops Widget
/// A list of tasks to be completed today with haptic feedback.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/config/app_theme.dart';

class DailyTask {
  final String id;
  final String title;
  final String time; // e.g., "08:00 AM"
  final bool isCompleted;
  final bool isCritical;

  const DailyTask({
    required this.id,
    required this.title,
    required this.time,
    this.isCompleted = false,
    this.isCritical = false,
  });
}

class DailyOpsWidget extends StatelessWidget {
  final List<DailyTask> tasks;
  final Function(String) onTaskToggle;

  const DailyOpsWidget({
    super.key,
    required this.tasks,
    required this.onTaskToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.glassBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'DAILY OPS',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Text(
                '${tasks.where((t) => t.isCompleted).length}/${tasks.length}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No tasks for today. Relax! 🌿',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _TaskItem(
                  task: task,
                  onToggle: () {
                    // Haptic: medium for check, heavy if ALL completed
                    if (!task.isCompleted) {
                      final willAllComplete = tasks
                              .where((t) => t.id != task.id)
                              .every((t) => t.isCompleted);
                      if (willAllComplete) {
                        HapticFeedback.heavyImpact();
                      } else {
                        HapticFeedback.mediumImpact();
                      }
                    } else {
                      HapticFeedback.lightImpact();
                    }
                    onTaskToggle(task.id);
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final DailyTask task;
  final VoidCallback onToggle;

  const _TaskItem({
    required this.task,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: task.isCompleted
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.glassBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.isCompleted
                ? AppTheme.primary.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: task.isCompleted ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: task.isCompleted ? AppTheme.primary : AppTheme.textSecondary,
                  width: 2,
                ),
              ),
              child: task.isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.black,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      color: task.isCompleted
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (task.time.isNotEmpty)
                    Text(
                      task.time,
                      style: TextStyle(
                        color: AppTheme.textSecondary.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (task.isCritical && !task.isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'URGENT',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
