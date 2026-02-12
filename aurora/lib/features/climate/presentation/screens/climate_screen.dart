/// Pantalla principal de Climate Analytics.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../grow/presentation/providers/grow_providers.dart';
import '../../climate/domain/entities/climate_current_entity.dart';
import '../../climate/presentation/providers/climate_providers.dart';
import '../../climate/presentation/widgets/add_reading_sheet.dart';
import '../../climate/presentation/widgets/climate_trend_chart.dart';
import '../../climate/presentation/widgets/condition_card.dart';
import '../../climate/presentation/widgets/vpd_heatmap.dart';
import '../../../../core/utils/vpd_calculator.dart';

class ClimateScreen extends ConsumerStatefulWidget {
  const ClimateScreen({super.key});

  @override
  ConsumerState<ClimateScreen> createState() => _ClimateScreenState();
}

class _ClimateScreenState extends ConsumerState<ClimateScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final growState = ref.read(activeGrowProvider);
      if (growState.hasActiveGrow) {
        final growId = growState.activeGrow!.id;
        ref.read(climateCurrentProvider.notifier).loadCurrent(growId);
        ref.read(climateHistoryProvider.notifier).loadHistory(growId);
        ref.read(climateAnalysisProvider.notifier).loadAnalysis(growId);
      }
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      final growState = ref.read(activeGrowProvider);
      if (!growState.hasActiveGrow) return;

      final growId = growState.activeGrow!.id;
      int days = 7;
      switch (_tabController.index) {
        case 1:
          days = 1;
          break; // 24h
        case 2:
          days = 7;
          break; // 7d
        case 3:
          days = 30;
          break; // 30d
      }
      
      if (_tabController.index > 0) {
        ref.read(climateHistoryProvider.notifier).loadHistory(growId, days: days);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddReadingSheet() {
    final state = ref.read(climateCurrentProvider);
    final phase = state.current?.phase ?? 'vegetative';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddReadingSheet(phase: phase),
    );
  }

  @override
  Widget build(BuildContext context) {
    final growState = ref.watch(activeGrowProvider);
    final currentState = ref.watch(climateCurrentProvider);

    if (!growState.hasActiveGrow) {
      return const Scaffold(
        body: Center(child: Text('No hay cultivo activo')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.thermostat_rounded, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Climate Analytics'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Ahora'),
            Tab(text: '24h'),
            Tab(text: '7d'),
            Tab(text: '30d'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final growId = growState.activeGrow!.id;
          await Future.wait([
            ref.read(climateCurrentProvider.notifier).loadCurrent(growId),
            ref.read(climateHistoryProvider.notifier).loadHistory(growId),
            ref.read(climateAnalysisProvider.notifier).loadAnalysis(growId),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 0) {
                return _buildCurrentView(currentState);
              } else {
                return _buildHistoryView();
              }
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReadingSheet,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildCurrentView(ClimateCurrentState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(child: Text('Error: ${state.errorMessage}'));
    }

    if (state.current?.reading == null) {
      return Center(
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.cloud_off, size: 48, color: AppTheme.textSecondary),
                const SizedBox(height: 16),
                const Text(
                  'No hay datos registrados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Registra tu primera lectura climática para ver el análisis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _showAddReadingSheet,
                  child: const Text('Registrar Datos'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final reading = state.current!.reading!;
    final ideal = state.current!.ideal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Environment Score
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Environment Score',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    Text(
                      '${state.environmentScore}',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(state.environmentScore),
                      ),
                    ),
                    Text(
                      _getScoreLabel(state.environmentScore),
                      style: TextStyle(
                        color: _getScoreColor(state.environmentScore),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: state.environmentScore / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation(
                            _getScoreColor(state.environmentScore)),
                      ),
                      Icon(state.vpdZone.icon,
                          color: state.vpdZone.color, size: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Grid de condiciones
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            ConditionCard(
              label: 'Temperatura',
              value: '${reading.temperature.toStringAsFixed(1)}°C',
              icon: Icons.thermostat,
              iconColor: _getTempColor(reading.temperature, ideal),
              isAlert: reading.temperature > ideal.tempMax ||
                  reading.temperature < ideal.tempMin,
            ),
            ConditionCard(
              label: 'Humedad',
              value: '${reading.humidity.toStringAsFixed(0)}%',
              icon: Icons.water_drop,
              iconColor: _getHumColor(reading.humidity, ideal),
              isAlert: reading.humidity > ideal.humidityMax ||
                  reading.humidity < ideal.humidityMin,
            ),
            ConditionCard(
              label: 'VPD',
              value: '${reading.vpd.toStringAsFixed(2)} kPa',
              icon: state.vpdZone.icon,
              iconColor: state.vpdZone.color,
              isAlert: state.vpdZone == VPDZone.danger ||
                  state.vpdZone == VPDZone.critical,
            ),
            if (reading.ph != null)
              ConditionCard(
                label: 'pH',
                value: reading.ph!.toStringAsFixed(1),
                icon: Icons.science,
                iconColor: _getPhColor(reading.ph!, ideal),
              )
            else
              ConditionCard(
                label: 'EC',
                value: reading.ec?.toStringAsFixed(1) ?? '—',
                icon: Icons.electric_bolt,
                iconColor: Colors.white70,
              ),
          ],
        ),
        const SizedBox(height: 16),

        // 3. VPD Heatmap
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: VPDHeatmap(
              currentTemp: reading.temperature,
              currentHumidity: reading.humidity,
              phase: state.current!.phase,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 4. AI Analysis
        _buildAnalysisSection(),

        const SizedBox(height: 16),
        Text(
          'Último registro: ${_formatTimeAgo(reading.createdAt)}',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildHistoryView() {
    final historyState = ref.watch(climateHistoryProvider);
    final currentState = ref.watch(climateCurrentProvider);

    if (historyState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (historyState.errorMessage != null) {
      return Center(child: Text('Error: ${historyState.errorMessage}'));
    }

    final history = historyState.history;
    if (history == null || history.readings.isEmpty) {
      return const Center(
          child: Text('No hay historial para este período',
              style: TextStyle(color: AppTheme.textSecondary)));
    }

    final stats = history.stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Stats Summary
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Temp Prom',
                  value: '${stats.avgTemp.toStringAsFixed(1)}°C',
                  subLabel: '${stats.minTemp.round()}-${stats.maxTemp.round()}°',
                  color: Colors.orangeAccent,
                ),
                _StatItem(
                  label: 'Hum Prom',
                  value: '${stats.avgHumidity.toStringAsFixed(0)}%',
                  subLabel:
                      '${stats.minHumidity.round()}-${stats.maxHumidity.round()}%',
                  color: Colors.lightBlueAccent,
                ),
                _StatItem(
                  label: 'Registros',
                  value: '${stats.readingsCount}',
                  subLabel: 'total',
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 2. Trend Chart
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 250,
              child: ClimateTrendChart(
                readings: history.readings,
                ideal: currentState.current?.ideal,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. VPD Heatmap (Static)
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: VPDHeatmap(
              phase: currentState.current?.phase ?? 'vegetative',
              // No pasamos currentTemp/Hum para que no pinte el punto
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildAnalysisSection() {
    final analysisState = ref.watch(climateAnalysisProvider);

    if (analysisState.isLoading) {
      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
    }
    
    if (analysisState.analysis == null) return const SizedBox.shrink();

    final analysis = analysisState.analysis!;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Aurora dice:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    analysis.message,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  if (analysis.alerts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: analysis.alerts.map((alert) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(alert.severity)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: _getSeverityColor(alert.severity)
                                    .withOpacity(0.5)),
                          ),
                          child: Text(
                            alert.message,
                            style: TextStyle(
                              color: _getSeverityColor(alert.severity),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---

  String _getScoreLabel(int score) {
    if (score >= 85) return 'Excelente';
    if (score >= 70) return 'Bueno';
    if (score >= 50) return 'Atención';
    return 'Crítico';
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return AppTheme.success;
    if (score >= 70) return AppTheme.warning;
    if (score >= 50) return Colors.orange;
    return AppTheme.error;
  }

  Color _getTempColor(double val, ClimateIdealEntity ideal) {
    if (val >= ideal.tempMin && val <= ideal.tempMax) return AppTheme.success;
    if (val < ideal.tempMin - 2 || val > ideal.tempMax + 2) return AppTheme.error;
    return AppTheme.warning;
  }

  Color _getHumColor(double val, ClimateIdealEntity ideal) {
    if (val >= ideal.humidityMin && val <= ideal.humidityMax) return AppTheme.success;
    if (val < ideal.humidityMin - 5 || val > ideal.humidityMax + 5) return AppTheme.error;
    return AppTheme.warning;
  }
  
  Color _getPhColor(double val, ClimateIdealEntity ideal) {
    if (ideal.phMin == null || ideal.phMax == null) return Colors.white70;
    if (val >= ideal.phMin! && val <= ideal.phMax!) return AppTheme.success;
    return AppTheme.warning;
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'high':
        return AppTheme.error;
      case 'medium':
        return AppTheme.warning;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String subLabel;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(subLabel,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary)),
      ],
    );
  }
}
