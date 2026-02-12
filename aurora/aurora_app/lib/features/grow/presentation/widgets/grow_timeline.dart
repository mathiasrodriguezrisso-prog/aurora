
import 'package:flutter/material.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/glass_container.dart';

class GrowTimeline extends StatelessWidget {
  final Map<String, dynamic> growData;

  const GrowTimeline({super.key, required this.growData});

  @override
  Widget build(BuildContext context) {
    // Extract phases from JSON
    final phases = (growData['configuration'] != null && growData['configuration']['plan'] != null)
        ? (growData['configuration']['plan']['phases'] as List?) 
        // fallback if structure differs
        : (growData['plan_data'] != null ? growData['plan_data']['phases'] as List? : []);
        
    if (phases == null || phases.isEmpty) {
      return const Center(child: Text("No plan data available", style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: phases.length,
      itemBuilder: (context, index) {
        final phase = phases[index];
        final isCurrent = index == 0; // Mock logic for MVP
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassContainer(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: isCurrent ? AppTheme.primary : Colors.white12,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(color: isCurrent ? Colors.black : Colors.white),
                ),
              ),
              title: Text(phase['name'] ?? 'Phase ${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(phase['duration'] ?? '', style: const TextStyle(color: Colors.white54)),
              iconColor: Colors.white54,
              collapsedIconColor: Colors.white54,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Parameters
                      if (phase['parameters'] != null)
                         Wrap(
                           spacing: 8,
                           children: (phase['parameters'] as Map).entries.map((e) => 
                             Chip(
                               label: Text('${e.key}: ${e.value}'),
                               backgroundColor: Colors.white10,
                               labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                               padding: EdgeInsets.zero,
                               side: BorderSide.none,
                             )
                           ).toList(),
                         ),
                      
                      const SizedBox(height: 12),
                      
                      // Events
                      if (phase['events'] != null)
                        ...(phase['events'] as List).map((evt) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Text('Day ${evt['day']}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                          title: Text(evt['action'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          subtitle: evt['detail'] != null ? Text(evt['detail'], style: const TextStyle(color: Colors.white54, fontSize: 12)) : null,
                        )),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
