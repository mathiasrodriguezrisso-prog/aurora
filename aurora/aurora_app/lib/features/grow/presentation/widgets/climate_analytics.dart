
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/aurora_text_field.dart';
import '../../data/providers/sensor_providers.dart';

class ClimateAnalytics extends ConsumerStatefulWidget {
  final String growId;
  const ClimateAnalytics({super.key, required this.growId});

  @override
  ConsumerState<ClimateAnalytics> createState() => _ClimateAnalyticsState();
}

class _ClimateAnalyticsState extends ConsumerState<ClimateAnalytics> {
  
  void _showManualEntrySheet(BuildContext context) {
    final tempCtrl = TextEditingController();
    final humidCtrl = TextEditingController();
    final phCtrl = TextEditingController();
    final ecCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Record Reading", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            AuroraTextField(hint: 'Temperature (°C)', controller: tempCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            AuroraTextField(hint: 'Humidity (%)', controller: humidCtrl, keyboardType: TextInputType.number),
             const SizedBox(height: 12),
            AuroraTextField(hint: 'pH (Optional)', controller: phCtrl, keyboardType: TextInputType.number),
             const SizedBox(height: 12),
            AuroraTextField(hint: 'EC (Optional)', controller: ecCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
                onPressed: () {
                  final t = double.tryParse(tempCtrl.text);
                  final h = double.tryParse(humidCtrl.text);
                  final pv = double.tryParse(phCtrl.text);
                  final ev = double.tryParse(ecCtrl.text);
                  
                  if (t != null && h != null) {
                    ref.read(submitSensorReadingProvider)(widget.growId, t, h, pv, ev);
                    Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reading saved!'), backgroundColor: AppTheme.primary));
                    }
                  }
                },
                child: const Text('Save'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Color _getVpdColor(double? vpd) {
    if (vpd == null) return Colors.white;
    if (vpd >= 0.8 && vpd <= 1.25) return AppTheme.primary; // Optimal Veg
    if (vpd >= 0.4 && vpd <= 1.6) return Colors.orange; // Acceptable
    return AppTheme.error; // Critical
  }

  String _getVpdStatus(double? vpd) {
    if (vpd == null) return "--";
    if (vpd >= 0.8 && vpd <= 1.25) return "Optimal ✅";
    if (vpd < 0.8) return "Low ⚠️";
    return "High ⚠️";
  }

  String _formatTime(DateTime dt) {
    return DateFormat('HH:mm, MMM dd').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final latestSensor = ref.watch(latestSensorProvider(widget.growId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: latestSensor.when(
        data: (sensor) {
          if (sensor == null) {
            return Column(
              children: [
                const EmptyState(icon: Icons.thermostat, message: "No sensor data yet"),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Record Manual Reading"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
                  onPressed: () => _showManualEntrySheet(context),
                ),
              ],
            );
          }
          
          return Column(
            children: [
              GlassContainer(
                child: Column(
                  children: [
                    const Text("Current VPD", style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 8),
                    Text(
                      sensor.vpd != null ? "${sensor.vpd!.toStringAsFixed(2)} kPa" : "N/A",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _getVpdColor(sensor.vpd),
                      ),
                    ),
                    Text(_getVpdStatus(sensor.vpd), style: TextStyle(color: _getVpdColor(sensor.vpd))),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              GlassContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Latest Reading", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildRow("Temperature", "${sensor.temperature?.toStringAsFixed(1) ?? '--'}°C"),
                    _buildRow("Humidity", "${sensor.humidity?.toStringAsFixed(0) ?? '--'}%"),
                    _buildRow("pH", sensor.ph?.toStringAsFixed(1) ?? '--'),
                    _buildRow("EC", sensor.ec?.toStringAsFixed(2) ?? '--'),
                    const SizedBox(height: 8),
                    Text("Updated: ${_formatTime(sensor.createdAt)}", style: const TextStyle(color: Colors.white30, fontSize: 11)),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add New Reading"),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
                onPressed: () => _showManualEntrySheet(context),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e,s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
