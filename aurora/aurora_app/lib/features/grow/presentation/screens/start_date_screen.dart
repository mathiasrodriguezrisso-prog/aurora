
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/aurora_button.dart';

class StartDateScreen extends StatefulWidget {
  final Map<String, dynamic> extra;
  const StartDateScreen({super.key, required this.extra});

  @override
  State<StartDateScreen> createState() => _StartDateScreenState();
}

class _StartDateScreenState extends State<StartDateScreen> {
  DateTime _startDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final config = widget.extra;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text("Start Date")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Summary Card
            GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSummaryRow("Strain", config['strain'] ?? 'Unknown'),
                  _buildSummaryRow("Seed", config['seed_type'] ?? '-'),
                  _buildSummaryRow("Medium", config['medium'] ?? '-'),
                  _buildSummaryRow("Light", "${config['light_type'] ?? '-'} ${config['watts']}W"),
                ],
              ),
            ),

            const SizedBox(height: 24),
            
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Select Start Date", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            
            const SizedBox(height: 8),
            
            GlassContainer(
              padding: const EdgeInsets.all(0),
              child: Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppTheme.primary,
                    surface: Colors.transparent, 
                    onSurface: Colors.white,
                  ),
                  dialogBackgroundColor: AppTheme.surface,
                ),
                child: CalendarDatePicker(
                  initialDate: _startDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now(),
                  onDateChanged: (date) => setState(() => _startDate = date),
                ),
              ),
            ),

            const SizedBox(height: 32),

            AuroraButton(
              text: "Generate Plan with AI 🤖",
              onPressed: () {
                context.push('/grow/generating', extra: {
                  ...config,
                  'start_date': _startDate.toIso8601String(),
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
