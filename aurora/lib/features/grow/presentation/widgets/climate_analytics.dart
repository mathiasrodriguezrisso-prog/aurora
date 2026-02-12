/// 📁 lib/features/grow/presentation/widgets/climate_analytics.dart
/// Climate tab showing sensor data, VPD, and historical trends.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_theme.dart';

class ClimateAnalytics extends ConsumerStatefulWidget {
  final Map<String, dynamic>? sensorData;
  final String growId;

  const ClimateAnalytics({
    super.key,
    this.sensorData,
    required this.growId,
  });

  @override
  ConsumerState<ClimateAnalytics> createState() => _ClimateAnalyticsState();
}

class _ClimateAnalyticsState extends ConsumerState<ClimateAnalytics> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  String _selectedRange = '24h';

  static const _ranges = ['6h', '12h', '24h', '48h', '7d'];

  int get _rangeLimitCount {
    switch (_selectedRange) {
      case '6h': return 12;
      case '12h': return 24;
      case '24h': return 48;
      case '48h': return 96;
      case '7d': return 336;
      default: return 48;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final response = await Supabase.instance.client
          .from('sensor_readings')
          .select()
          .eq('grow_id', widget.growId)
          .order('created_at', ascending: true)
          .limit(_rangeLimitCount);

      setState(() {
        _history = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final temp =
        (widget.sensorData?['temperature'] as num?)?.toDouble();
    final hum =
        (widget.sensorData?['humidity'] as num?)?.toDouble();
    final ph =
        (widget.sensorData?['ph'] as num?)?.toDouble();

    double? vpd;
    if (temp != null && hum != null) {
      final svp = 0.6108 * _svpCalc(temp);
      vpd = svp * (1 - hum / 100);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Readings
          _buildSectionLabel('Current Readings'),
          const SizedBox(height: 8),
          _buildCurrentReadings(temp, hum, ph, vpd),
          const SizedBox(height: 24),

          // VPD Zone
          if (vpd != null) ...[
            _buildSectionLabel('VPD Zone'),
            const SizedBox(height: 8),
            _buildVpdIndicator(vpd),
            const SizedBox(height: 24),
          ],

          // Manual Entry Button
          _buildManualEntryButton(),
          const SizedBox(height: 24),

          // Chart Range Selector
          _buildRangeSelector(),
          const SizedBox(height: 12),

          // Temperature History
          if (_history.isNotEmpty) ...[
            _buildSectionLabel('Temperature ($_selectedRange)'),
            const SizedBox(height: 8),
            _buildChart(
              _history,
              'temperature',
              AppTheme.error,
              '°C',
            ),
            const SizedBox(height: 24),

            _buildSectionLabel('Humidity ($_selectedRange)'),
            const SizedBox(height: 8),
            _buildChart(
              _history,
              'humidity',
              Colors.blueAccent,
              '%',
            ),
          ] else if (_loading) ...[
            _buildSectionLabel('Loading history...'),
            const SizedBox(height: 12),
            Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 2,
              ),
            ),
          ] else ...[
            _buildSectionLabel('No sensor history available'),
          ],
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Row(
      children: _ranges.map((r) {
        final isActive = _selectedRange == r;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedRange = r);
              _loadHistory();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primary.withValues(alpha: 0.15)
                    : AppTheme.glassBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive ? AppTheme.primary : AppTheme.glassBorder,
                ),
              ),
              child: Center(
                child: Text(
                  r,
                  style: TextStyle(
                    color: isActive ? AppTheme.primary : AppTheme.textTertiary,
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildManualEntryButton() {
    return GestureDetector(
      onTap: _showManualEntrySheet,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: AppTheme.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manual Entry',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Log sensor readings manually',
                        style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: AppTheme.textTertiary, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showManualEntrySheet() {
    final tempCtrl = TextEditingController();
    final humCtrl = TextEditingController();
    final phCtrl = TextEditingController();
    final ecCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Manual Sensor Entry',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _EntryField(controller: tempCtrl, label: 'Temp (°C)', icon: Icons.thermostat),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _EntryField(controller: humCtrl, label: 'RH (%)', icon: Icons.water_drop),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _EntryField(controller: phCtrl, label: 'pH', icon: Icons.science),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _EntryField(controller: ecCtrl, label: 'EC (mS)', icon: Icons.electric_bolt),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _submitManualReading(
                      temp: double.tryParse(tempCtrl.text),
                      humidity: double.tryParse(humCtrl.text),
                      ph: double.tryParse(phCtrl.text),
                      ec: double.tryParse(ecCtrl.text),
                    );
                  },
                  child: const Text('Save Reading', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitManualReading({
    double? temp,
    double? humidity,
    double? ph,
    double? ec,
  }) async {
    if (temp == null && humidity == null && ph == null && ec == null) return;

    try {
      final sb = Supabase.instance.client;
      await sb.from('sensor_readings').insert({
        'grow_id': widget.growId,
        'user_id': sb.auth.currentUser?.id,
        if (temp != null) 'temperature': temp,
        if (humidity != null) 'humidity': humidity,
        if (ph != null) 'ph': ph,
        if (ec != null) 'ec': ec,
      });

      HapticFeedback.mediumImpact();
      await _loadHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Reading saved'),
            backgroundColor: AppTheme.primary.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCurrentReadings(
      double? temp, double? hum, double? ph, double? vpd) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ReadingTile(label: 'Temp', value: temp?.toStringAsFixed(1) ?? '--', unit: '°C', icon: Icons.thermostat),
              _ReadingTile(label: 'RH', value: hum?.toStringAsFixed(0) ?? '--', unit: '%', icon: Icons.water_drop),
              _ReadingTile(label: 'pH', value: ph?.toStringAsFixed(1) ?? '--', unit: '', icon: Icons.science),
              _ReadingTile(label: 'VPD', value: vpd?.toStringAsFixed(2) ?? '--', unit: 'kPa', icon: Icons.air),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVpdIndicator(double vpd) {
    final zone = _getVpdZone(vpd);
    final position = ((vpd - 0.2) / 1.8).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    zone.label,
                    style: TextStyle(
                      color: zone.color,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${vpd.toStringAsFixed(2)} kPa',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Gradient bar with marker
              Stack(
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.blue,
                          Colors.green,
                          Colors.orange,
                          Colors.red,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: position *
                        (MediaQuery.of(context).size.width - 80),
                    child: Container(
                      width: 4,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('0.2', style: TextStyle(color: AppTheme.textTertiary, fontSize: 10)),
                  Text('0.8', style: TextStyle(color: AppTheme.textTertiary, fontSize: 10)),
                  Text('1.2', style: TextStyle(color: AppTheme.textTertiary, fontSize: 10)),
                  Text('2.0', style: TextStyle(color: AppTheme.textTertiary, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(
    List<Map<String, dynamic>> data,
    String field,
    Color color,
    String unit,
  ) {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final val = (data[i][field] as num?)?.toDouble();
      if (val != null) {
        spots.add(FlSpot(i.toDouble(), val));
      }
    }

    if (spots.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('No data', style: TextStyle(color: AppTheme.textTertiary)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 180,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppTheme.glassBorder,
                  strokeWidth: 0.5,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}$unit',
                      style: const TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                bottomTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: color,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withValues(alpha: 0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y.toStringAsFixed(1)}$unit',
                        TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _VpdZone _getVpdZone(double vpd) {
    if (vpd < 0.4) return _VpdZone('Low Transpiration', Colors.blue);
    if (vpd < 0.8) return _VpdZone('Propagation Zone', Colors.teal);
    if (vpd <= 1.2) return _VpdZone('Optimal Zone ✓', AppTheme.primary);
    if (vpd <= 1.6) return _VpdZone('High Transpiration', Colors.orange);
    return _VpdZone('Danger Zone', AppTheme.error);
  }

  double _svpCalc(double temp) {
    // Taylor series: e^((17.27 * T) / (T + 237.3))
    final exponent = (17.27 * temp) / (temp + 237.3);
    double result = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 20; i++) {
      term *= exponent / i;
      result += term;
    }
    return result;
  }
}

class _VpdZone {
  final String label;
  final Color color;
  const _VpdZone(this.label, this.color);
}

class _ReadingTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _ReadingTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.textTertiary),
        const SizedBox(height: 6),
        Text(
          '$value$unit',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
        ),
      ],
    );
  }
}

class _EntryField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _EntryField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: AppTheme.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        fillColor: AppTheme.glassBackground,
        filled: true,
      ),
    );
  }
}
