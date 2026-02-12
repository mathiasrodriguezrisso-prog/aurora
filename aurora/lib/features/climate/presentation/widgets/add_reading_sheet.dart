/// Bottom Sheet para registrar datos climáticos manuales.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../core/utils/vpd_calculator.dart';
import '../../../../shared/widgets/aurora_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/glass_slider.dart';
import '../../../../shared/widgets/glass_toggle.dart';
import '../../grow/presentation/providers/grow_providers.dart';
import '../providers/climate_providers.dart';

class AddReadingSheet extends ConsumerStatefulWidget {
  final String phase;

  const AddReadingSheet({super.key, required this.phase});

  @override
  ConsumerState<AddReadingSheet> createState() => _AddReadingSheetState();
}

class _AddReadingSheetState extends ConsumerState<AddReadingSheet> {
  // Valores iniciales promedio
  double _temperature = 24.0;
  double _humidity = 55.0;
  double? _ph;
  double? _ec;
  bool _watered = false;
  final TextEditingController _notesController = TextEditingController();

  // Estado UI
  bool _isSubmitting = false;
  bool _showExtra = false; // Expandir pH/EC

  // VPD calculado en tiempo real
  double _calculatedVpd = 0.0;
  VPDZone _calculatedZone = VPDZone.optimal;

  @override
  void initState() {
    super.initState();
    _recalculateVPD();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _recalculateVPD() {
    setState(() {
      _calculatedVpd =
          VPDCalculator.calculateVPD(_temperature, _humidity);
      _calculatedZone =
          VPDCalculator.getVPDZone(_calculatedVpd, widget.phase);
    });
  }

  Future<void> _submit() async {
    final growState = ref.read(activeGrowProvider);
    if (!growState.hasActiveGrow) return;

    setState(() => _isSubmitting = true);

    final success = await ref
        .read(climateCurrentProvider.notifier)
        .addReading(
          growId: growState.activeGrow!.id,
          temperature: _temperature,
          humidity: _humidity,
          ph: _ph,
          ec: _ec,
          watered: _watered,
          notes: _notesController.text.isNotEmpty
              ? _notesController.text
              : null,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lectura registrada correctamente ✅'),
            backgroundColor: AppTheme.success.withValues(alpha: 0.8),
          ),
        );
        // También recargar historial
        ref
            .read(climateHistoryProvider.notifier)
            .loadHistory(growState.activeGrow!.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar datos ❌'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.glassBorder)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Registrar Datos',
              style: AppTheme.darkTheme.textTheme.titleLarge,
            ),
            const SizedBox(height: 24),

            // Sliders principales
            GlassSlider(
              label: 'Temperatura',
              unit: '°C',
              value: _temperature,
              min: 15,
              max: 40,
              divisions: 50, // 0.5 step
              onChanged: (v) {
                _temperature = v;
                _recalculateVPD();
              },
            ),
            const SizedBox(height: 20),

            GlassSlider(
              label: 'Humedad',
              unit: '%',
              value: _humidity,
              min: 20,
              max: 95,
              divisions: 75, // 1 step
              activeColor: const Color(0xFF4FC3F7),
              onChanged: (v) {
                _humidity = v;
                _recalculateVPD();
              },
            ),
            const SizedBox(height: 20),

            // VPD en tiempo real
            GlassCard(
              backgroundColor: _calculatedZone.color.withValues(alpha: 0.1),
              borderColor: _calculatedZone.color.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(_calculatedZone.icon,
                        color: _calculatedZone.color, size: 24),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VPD: ${_calculatedVpd.toStringAsFixed(2)} kPa',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _calculatedZone.label,
                          style: TextStyle(
                            color: _calculatedZone.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Toggle Watered
            GlassToggle(
              value: _watered,
              label: '¿Regaste hoy?',
              icon: Icons.water_drop,
              onChanged: (v) => setState(() => _watered = v),
            ),

            // Opcionales (pH / EC)
            ExpansionTile(
              title: const Text(
                'Datos de Riego (Opcional)',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              initiallyExpanded: _showExtra,
              onExpansionChanged: (v) => setState(() => _showExtra = v),
              tilePadding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                _OptionalSlider(
                  label: 'pH',
                  unit: '',
                  value: _ph,
                  min: 4.0,
                  max: 8.0,
                  divisions: 40,
                  onChanged: (v) => setState(() => _ph = v),
                ),
                const SizedBox(height: 16),
                _OptionalSlider(
                  label: 'EC (Electroconductividad)',
                  unit: 'mS/cm',
                  value: _ec,
                  min: 0.0,
                  max: 3.0,
                  divisions: 30,
                  onChanged: (v) => setState(() => _ec = v),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notas
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Notas (observaciones rápidas)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            AuroraButton(
              text: 'Guardar Registro',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _OptionalSlider extends StatelessWidget {
  final String label;
  final String unit;
  final double? value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double?> onChanged;

  const _OptionalSlider({
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = value != null;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Switch(
              value: isEnabled,
              activeColor: AppTheme.primary,
              onChanged: (enabled) {
                if (enabled) {
                  onChanged((min + max) / 2); // default mid value
                } else {
                  onChanged(null);
                }
              },
            ),
          ],
        ),
        if (isEnabled)
          GlassSlider(
            label: '',
            unit: unit,
            value: value!,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (v) => onChanged(v),
          ),
      ],
    );
  }
}
