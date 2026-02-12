/// Wizard de configuración de cultivo en 5 pasos.
/// ConsumerStatefulWidget con PageView controlado, ref.listen para éxito/error.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../shared/widgets/glass_dropdown.dart';
import '../../../../shared/widgets/glass_search_bar.dart';
import '../../../../shared/widgets/glass_slider.dart';
import '../../../../shared/widgets/glass_toggle.dart';
import '../../../../shared/widgets/selectable_glass_card.dart';
import '../../../../shared/widgets/wizard_progress_bar.dart';
import '../../data/strain_catalog.dart';
import '../providers/grow_setup_provider.dart';

class GrowSetupWizard extends ConsumerStatefulWidget {
  const GrowSetupWizard({super.key});

  @override
  ConsumerState<GrowSetupWizard> createState() => _GrowSetupWizardState();
}

class _GrowSetupWizardState extends ConsumerState<GrowSetupWizard> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(growSetupProvider);
    final notifier = ref.read(growSetupProvider.notifier);

    // Escuchar cambios de estado
    ref.listen<GrowSetupState>(growSetupProvider, (prev, next) {
      // Sincronizar PageView con el step del provider
      if (prev?.currentStep != next.currentStep) {
        _pageController.animateToPage(
          next.currentStep,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }

      // Éxito → navegar a home
      if (next.isSuccess && !(prev?.isSuccess ?? false)) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Tu plan de cultivo está listo! 🌱'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.go('/home');
      }

      // Error → mostrar SnackBar
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1117), Color(0xFF0A0A0F)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Progreso
                  WizardProgressBar(
                    currentStep: state.currentStep,
                    totalSteps: 5,
                    stepLabels: const [
                      'Nivel',
                      'Tipo',
                      'Medio',
                      'Espacio',
                      'Cepa',
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Contenido del paso actual
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStep0ExperienceLevel(state, notifier),
                        _buildStep1GrowType(state, notifier),
                        _buildStep2Medium(state, notifier),
                        _buildStep3Space(state, notifier),
                        _buildStep4Strain(state, notifier),
                      ],
                    ),
                  ),

                  // Botones de navegación
                  _buildNavButtons(state, notifier),
                ],
              ),

              // Loading overlay
              if (state.isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aurora está diseñando tu plan...',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // PASO 0 — Nivel de experiencia
  // ═══════════════════════════════════════════════════

  Widget _buildStep0ExperienceLevel(GrowSetupState state, GrowSetupNotifier notifier) {
    const options = [
      {'icon': Icons.eco_outlined, 'title': 'Novato', 'subtitle': 'Mi primer cultivo', 'value': 'novice'},
      {'icon': Icons.grass, 'title': 'Intermedio', 'subtitle': 'He cosechado antes', 'value': 'intermediate'},
      {'icon': Icons.park, 'title': 'Experto', 'subtitle': 'Cultivo hace años', 'value': 'expert'},
    ];

    return _buildStepLayout(
      title: '¿Cuál es tu experiencia?',
      subtitle: 'Esto nos ayuda a adaptar las recomendaciones',
      child: Column(
        children: options.map((opt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SelectableGlassCard(
              key: ValueKey('exp_${opt['value']}'),
              icon: opt['icon'] as IconData,
              title: opt['title'] as String,
              subtitle: opt['subtitle'] as String,
              isSelected: state.data.experienceLevel == opt['value'],
              onTap: () => notifier.setExperienceLevel(opt['value'] as String),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // PASO 1 — Tipo de cultivo
  // ═══════════════════════════════════════════════════

  Widget _buildStep1GrowType(GrowSetupState state, GrowSetupNotifier notifier) {
    const options = [
      {'icon': Icons.home, 'title': 'Indoor', 'value': 'indoor'},
      {'icon': Icons.wb_sunny, 'title': 'Outdoor', 'value': 'outdoor'},
      {'icon': Icons.warehouse, 'title': 'Invernadero', 'value': 'greenhouse'},
      {'icon': Icons.forest, 'title': 'Guerrilla', 'value': 'guerrilla'},
    ];

    return _buildStepLayout(
      title: '¿Dónde cultivas?',
      subtitle: 'Selecciona tu entorno de cultivo',
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: options.map((opt) {
          return SelectableGlassCard(
            key: ValueKey('grow_${opt['value']}'),
            icon: opt['icon'] as IconData,
            title: opt['title'] as String,
            isSelected: state.data.growType == opt['value'],
            onTap: () => notifier.setGrowType(opt['value'] as String),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // PASO 2 — Medio de cultivo
  // ═══════════════════════════════════════════════════

  Widget _buildStep2Medium(GrowSetupState state, GrowSetupNotifier notifier) {
    const options = [
      {'icon': Icons.yard, 'title': 'Tierra', 'subtitle': 'La opción clásica y natural', 'value': 'soil'},
      {'icon': Icons.filter_vintage, 'title': 'Coco', 'subtitle': 'Fibra de coco — versátil y limpio', 'value': 'coco'},
      {'icon': Icons.water_drop, 'title': 'Hidroponía DWC', 'subtitle': 'Deep Water Culture — raíces en agua', 'value': 'hydro_dwc'},
      {'icon': Icons.loop, 'title': 'Hidroponía NFT', 'subtitle': 'Nutrient Film Technique — flujo continuo', 'value': 'hydro_nft'},
      {'icon': Icons.air, 'title': 'Aeroponía', 'subtitle': 'Raíces al aire — nivel avanzado', 'value': 'aeroponics'},
    ];

    return _buildStepLayout(
      title: '¿Qué medio de cultivo usas?',
      subtitle: 'Cada medio tiene sus ventajas',
      child: Column(
        children: options.map((opt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SelectableGlassCard(
              key: ValueKey('medium_${opt['value']}'),
              icon: opt['icon'] as IconData,
              title: opt['title'] as String,
              subtitle: opt['subtitle'] as String,
              isSelected: state.data.medium == opt['value'],
              onTap: () => notifier.setMedium(opt['value'] as String),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // PASO 3 — Espacio y equipamiento
  // ═══════════════════════════════════════════════════

  Widget _buildStep3Space(GrowSetupState state, GrowSetupNotifier notifier) {
    return _buildStepLayout(
      title: 'Configura tu espacio',
      subtitle: 'Iluminación, tamaño y ventilación',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.glassBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tamaño
            GlassSlider(
              label: 'Tamaño',
              value: state.data.spaceSizeM2,
              min: 0.5,
              max: 20.0,
              divisions: 39,
              unit: 'm²',
              onChanged: notifier.setSpaceSize,
            ),
            const SizedBox(height: 20),

            // Divider
            Divider(color: AppTheme.glassBorder, height: 1),
            const SizedBox(height: 16),

            // Tipo de iluminación
            const Text(
              'Tipo de iluminación',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            GlassDropdown(
              hint: 'Selecciona iluminación',
              selectedValue: state.data.lightType,
              items: const [
                DropdownItem(value: 'led', label: 'LED', icon: Icons.lightbulb),
                DropdownItem(value: 'hps', label: 'HPS', icon: Icons.wb_incandescent),
                DropdownItem(value: 'cmh', label: 'CMH', icon: Icons.tungsten),
                DropdownItem(value: 'cfl', label: 'CFL', icon: Icons.fluorescent),
                DropdownItem(value: 'sun', label: 'Sol natural', icon: Icons.wb_sunny),
              ],
              onChanged: notifier.setLightType,
            ),
            const SizedBox(height: 16),

            // Potencia (solo si no es sol)
            if (state.data.lightType != null && state.data.lightType != 'sun') ...[
              GlassSlider(
                label: 'Potencia',
                value: (state.data.lightWattage ?? 300).toDouble(),
                min: 50,
                max: 1000,
                divisions: 19,
                unit: 'W',
                onChanged: (v) => notifier.setLightWattage(v.toInt()),
              ),
              const SizedBox(height: 16),
            ],

            // Divider
            Divider(color: AppTheme.glassBorder, height: 1),
            const SizedBox(height: 12),

            // Toggles de equipamiento
            GlassToggle(
              icon: Icons.air,
              label: 'Extractor',
              value: state.data.hasExtractor,
              onChanged: notifier.setHasExtractor,
            ),
            GlassToggle(
              icon: Icons.toys_outlined,
              label: 'Ventilador',
              value: state.data.hasFan,
              onChanged: notifier.setHasFan,
            ),
            GlassToggle(
              icon: Icons.filter_alt,
              label: 'Filtro de carbón',
              value: state.data.hasCarbonFilter,
              onChanged: notifier.setHasCarbonFilter,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // PASO 4 — Cepa, tipo de semilla y fecha
  // ═══════════════════════════════════════════════════

  Widget _buildStep4Strain(GrowSetupState state, GrowSetupNotifier notifier) {
    final displayDate = state.data.startDate ?? DateTime.now();

    return _buildStepLayout(
      title: 'Elige tu cepa',
      subtitle: 'Busca o deja que Aurora recomiende',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Búsqueda de cepa
          GlassSearchBar(
            hint: 'Buscar cepa...',
            suggestions: kStrainNames,
            onSelected: notifier.setStrain,
          ),

          // Cepa seleccionada
          if (state.data.strain != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.eco, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    state.data.strain!,
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Recomendar aleatoria
          OutlinedButton.icon(
            onPressed: () => _recommendRandomStrain(notifier),
            icon: const Text('🤖', style: TextStyle(fontSize: 18)),
            label: const Text('Aurora, recomiéndame una'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 24),

          // Tipo de semilla
          const Text(
            'Tipo de semilla',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildSeedTypeChip(
                'Feminizada',
                'feminized',
                state.data.seedType,
                notifier,
              ),
              const SizedBox(width: 8),
              _buildSeedTypeChip(
                'Regular',
                'regular',
                state.data.seedType,
                notifier,
              ),
              const SizedBox(width: 8),
              _buildSeedTypeChip(
                'Auto',
                'autoflower',
                state.data.seedType,
                notifier,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Fecha de inicio
          GestureDetector(
            onTap: () => _pickStartDate(notifier),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.glassBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Fecha de inicio',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                  ),
                  const Spacer(),
                  Text(
                    state.data.startDate != null
                        ? _formatDate(displayDate)
                        : 'Hoy',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════

  /// Layout base para cada paso: título, subtítulo, contenido scrollable.
  Widget _buildStepLayout({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          child,
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Chip compacto para seleccionar tipo de semilla.
  Widget _buildSeedTypeChip(
    String label,
    String value,
    String? selected,
    GrowSetupNotifier notifier,
  ) {
    final isActive = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => notifier.setSeedType(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primary.withValues(alpha: 0.12)
                : AppTheme.glassBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? AppTheme.primary : AppTheme.glassBorder,
              width: isActive ? 1.5 : 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  /// Botones Anterior / Siguiente / Generar Plan.
  Widget _buildNavButtons(GrowSetupState state, GrowSetupNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          if (state.currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: notifier.previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: BorderSide(color: AppTheme.glassBorder),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Anterior'),
              ),
            ),
          if (state.currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: state.currentStep > 0 ? 2 : 1,
            child: state.currentStep < 4
                ? ElevatedButton(
                    onPressed: state.canAdvance ? notifier.nextStep : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                      disabledForegroundColor: Colors.black38,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Siguiente',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: state.canAdvance && !state.isLoading
                        ? notifier.submitGrowSetup
                        : null,
                    icon: const Text('🌱', style: TextStyle(fontSize: 18)),
                    label: const Text(
                      'Generar Plan',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                      disabledForegroundColor: Colors.black38,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Selecciona una cepa aleatoria con efecto de loading de 2 segundos.
  Future<void> _recommendRandomStrain(GrowSetupNotifier notifier) async {
    HapticFeedback.mediumImpact();

    // Mostrar loading brevemente
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: AppTheme.primary,
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Aurora está pensando...',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    final random = math.Random();
    final strain = kStrainCatalog[random.nextInt(kStrainCatalog.length)];
    notifier.setStrain(strain['name']!);

    if (mounted) Navigator.of(context).pop();
  }

  /// Abre el date picker con tema oscuro.
  Future<void> _pickStartDate(GrowSetupNotifier notifier) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primary,
              onPrimary: Colors.black,
              surface: AppTheme.surface,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      notifier.setStartDate(picked);
    }
  }

  /// Formatea una fecha como "dd Mmm yyyy" sin depender de intl.
  String _formatDate(DateTime date) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
