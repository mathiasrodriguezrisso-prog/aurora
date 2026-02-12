/// 📁 lib/features/profile/presentation/screens/settings_screen.dart
/// App settings screen with toggles for notifications, dark mode,
/// measurement units, and account actions.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/providers/profile_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final settings = settingsState.settings;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fondo oscuro profundo
          Container(color: const Color(0xFF0A0A0F)),
          
          // Efecto de brillo sutil
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionLabel('NOTIFICACIONES'),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          children: [
                            _ToggleTile(
                              icon: Icons.notifications_none_rounded,
                              label: 'Notificaciones Push',
                              value: settings.pushNotifications,
                              onChanged: (v) => ref
                                  .read(settingsProvider.notifier)
                                  .updateSetting('push_notifications', v),
                            ),
                            _buildDivider(),
                            _ToggleTile(
                              icon: Icons.mail_outline_rounded,
                              label: 'Notificaciones por Email',
                              value: settings.emailNotifications,
                              onChanged: (v) => ref
                                  .read(settingsProvider.notifier)
                                  .updateSetting('email_notifications', v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        _buildSectionLabel('APARIENCIA'),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          children: [
                            _ToggleTile(
                              icon: Icons.dark_mode_outlined,
                              label: 'Modo Oscuro',
                              value: settings.darkMode,
                              onChanged: (v) => ref
                                  .read(settingsProvider.notifier)
                                  .updateSetting('dark_mode', v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        _buildSectionLabel('SISTEMA DE MEDIDAS'),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          children: [
                            _RadioTile(
                              icon: Icons.straighten_rounded,
                              label: 'Métrico (°C, cm, kg)',
                              isSelected: settings.measurementUnit == 'metric',
                              onTap: () => ref
                                  .read(settingsProvider.notifier)
                                  .updateSetting('measurement_unit', 'metric'),
                            ),
                            _buildDivider(),
                            _RadioTile(
                              icon: Icons.square_foot_rounded,
                              label: 'Imperial (°F, in, lb)',
                              isSelected: settings.measurementUnit == 'imperial',
                              onTap: () => ref
                                  .read(settingsProvider.notifier)
                                  .updateSetting('measurement_unit', 'imperial'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        _buildSectionLabel('ACERCA DE'),
                        const SizedBox(height: 12),
                        _buildSettingsCard(
                          children: [
                            const _InfoTile(
                              icon: Icons.info_outline_rounded,
                              label: 'Versión',
                              value: '1.0.0 (BETA)',
                            ),
                            _buildDivider(),
                            _ActionTile(
                              icon: Icons.privacy_tip_outlined,
                              label: 'Política de Privacidad',
                              onTap: () {},
                            ),
                            _buildDivider(),
                            _ActionTile(
                              icon: Icons.description_outlined,
                              label: 'Términos de Servicio',
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),

                        _buildLogoutButton(context, ref),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          ),
          const Text(
            'Configuración',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.primary.withOpacity(0.7),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.white.withOpacity(0.05),
      height: 1,
      indent: 50,
      endIndent: 16,
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _showLogoutConfirmation(context, ref),
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
        label: const Text(
          'Cerrar Sesión',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF15151A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('¿Cerrar Sesión?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            '¿Estás seguro de que deseas salir de la aplicación?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            Container(
              margin: const EdgeInsets.all(8),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withOpacity(0.2),
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Colors.redAccent, width: 0.5),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
                child: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary, size: 22),
      title: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primary,
        activeTrackColor: AppTheme.primary.withOpacity(0.3),
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RadioTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary, size: 22),
      title: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
            width: 2,
          ),
        ),
        child: isSelected
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              )
            : const SizedBox(width: 10, height: 10),
      ),
      onTap: onTap,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary, size: 22),
      title: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Text(value,
          style: const TextStyle(color: AppTheme.textTertiary, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.textSecondary, size: 22),
      title: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.3), size: 20),
    );
  }
}
