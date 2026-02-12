
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/glass_container.dart';

class DailyOpsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final Function(String, bool) onToggle;

  const DailyOpsWidget({
    super.key,
    required this.tasks,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daily Tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '${tasks.where((t) => t['completed'] == true).length}/${tasks.length} completed',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Divider(color: AppTheme.glassBorder),
          
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('No tasks for today 🎉', style: TextStyle(color: Colors.white54)),
            )
          else
            ...tasks.map((task) {
              final completed = task['completed'] as bool;
              return Container(
                decoration: BoxDecoration(
                  border: task['priority'] == 'high' 
                    ? Border(left: BorderSide(color: AppTheme.error, width: 3)) 
                    : null
                ),
                child: CheckboxListTile(
                  value: completed,
                  activeColor: AppTheme.primary,
                  checkColor: Colors.black,
                  tileColor: Colors.transparent,
                  title: Text(
                    task['title'] ?? 'Task',
                    style: TextStyle(
                      color: completed ? Colors.white38 : Colors.white,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: task['description'] != null ? Text(task['description'], style: const TextStyle(color: Colors.white38, fontSize: 12)) : null,
                  secondary:  Icon(
                    _getIcon(task['type']),
                    color: completed ? Colors.white38 : AppTheme.primary,
                  ),
                  onChanged: (val) {
                    if (val != null) {
                      HapticFeedback.mediumImpact();
                      onToggle(task['id'], val);
                      
                      // Check for all complete
                      if (val && tasks.where((t) => t['completed'] == true).length + 1 == tasks.length) {
                        HapticFeedback.heavyImpact();
                      }
                    }
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'watering': return Icons.water_drop;
      case 'feeding': return Icons.science;
      case 'training': return Icons.content_cut;
      default: return Icons.check_circle_outline;
    }
  }
}
