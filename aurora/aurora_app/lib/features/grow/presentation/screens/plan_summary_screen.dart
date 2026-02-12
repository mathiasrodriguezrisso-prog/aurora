
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aurora_app/core/config/app_theme.dart';
import 'package:aurora_app/shared/widgets/glass_container.dart';

class PlanSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> extra;
  const PlanSummaryScreen({super.key, required this.extra});

  @override
  State<PlanSummaryScreen> createState() => _PlanSummaryScreenState();
}

class _PlanSummaryScreenState extends State<PlanSummaryScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> plan = widget.extra['plan'] as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> config = widget.extra['config'] as Map<String, dynamic>? ?? {};
    final bool isFallback = widget.extra['is_fallback'] == true || plan['ai_generated'] == false;
    final phases = plan['phases'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text("Your Grow Plan")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fallback Warning
            if (isFallback) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Basic plan (AI unavailable). Connect the backend for a customized AI plan.",
                        style: TextStyle(color: Colors.amber, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Header
            GlassContainer(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Text(
                      config['strain']?.toString() ?? plan['strain']?.toString() ?? 'Unknown',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Estimated: ${plan['estimated_days']?.toString() ?? '90'} days",
                      style: const TextStyle(color: AppTheme.primary, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${config['medium'] ?? ''} • ${config['light_type'] ?? ''} ${config['watts'] ?? ''}W".replaceAll('  ', ' ').trim(),
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Text("Growth Phases", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),

            if (phases.isEmpty)
              const Center(child: Text("Plan details will appear here", style: TextStyle(color: Colors.white54)))
            else
              ...phases.map((phase) {
                final phaseMap = phase as Map<String, dynamic>? ?? {};
                final params = phaseMap['parameters'] as Map<String, dynamic>?;
                final events = phaseMap['events'] as List<dynamic>?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              phaseMap['name']?.toString() ?? 'Phase',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              phaseMap['duration']?.toString() ?? '',
                              style: const TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                          ],
                        ),
                        if (params != null && params.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: params.entries.map((e) => Chip(
                              label: Text("${e.key}: ${e.value}", style: const TextStyle(fontSize: 12)),
                              backgroundColor: Colors.white10,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                              padding: EdgeInsets.zero,
                              side: BorderSide.none,
                            )).toList(),
                          ),
                        ],
                        if (events != null && events.isNotEmpty) ...[
                          const Divider(color: Colors.white24, height: 20),
                          ...events.map((evt) {
                            final evtMap = evt as Map<String, dynamic>? ?? {};
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Day ${evtMap['day'] ?? '?'}: ",
                                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "${evtMap['action'] ?? ''} - ${evtMap['detail'] ?? ''}",
                                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.eco),
                label: _isSaving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text("Start Growing! 🌱", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: _isSaving ? null : () async {
                  setState(() => _isSaving = true);
                  try {
                    final supabase = Supabase.instance.client;
                    final userId = supabase.auth.currentUser?.id;

                    if (userId == null) {
                      throw Exception('Not authenticated');
                    }

                    await supabase.from('grows').insert({
                      'user_id': userId,
                      'strain_name': config['strain']?.toString() ?? plan['strain']?.toString() ?? 'Unknown',
                      'medium': config['medium']?.toString(),
                      'status': 'active',
                      'start_date': config['start_date']?.toString() ?? DateTime.now().toIso8601String(),
                      'configuration': config,
                      'plan_data': plan,
                    });

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Grow started! 🌱'), backgroundColor: AppTheme.primary),
                    );
                    context.go('/home');
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
