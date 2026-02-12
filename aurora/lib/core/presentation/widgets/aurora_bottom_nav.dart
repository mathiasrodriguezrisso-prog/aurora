/// 📁 lib/core/presentation/widgets/aurora_bottom_nav.dart
/// Barra de navegación inferior con 5 espacios, diseño Glassmorphism,
/// integración con Riverpod para medallas de notificaciones y 
/// FAB central elevado.
library;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../../features/notifications/presentation/providers/notification_providers.dart';

/// Callback emitido cuando se selecciona una pestaña.
typedef OnTabSelected = void Function(int index);

class AuroraBottomNav extends ConsumerStatefulWidget {
  final int currentIndex;
  final OnTabSelected onTabSelected;
  final VoidCallback onCreatePressed;

  const AuroraBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCreatePressed,
  });

  @override
  ConsumerState<AuroraBottomNav> createState() => _AuroraBottomNavState();
}

class _AuroraBottomNavState extends ConsumerState<AuroraBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fabScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 80 + MediaQuery.of(context).padding.bottom,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: const Color(0xFF101015).withOpacity(0.85),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTab(0, Icons.dashboard_rounded, 'Home'),
              _buildTab(1, Icons.eco_rounded, 'Grow'),
              _buildFab(),
              _buildTab(3, Icons.rss_feed_rounded, 'Feed'),
              _buildTab(4, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isActive = widget.currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTabSelected(index);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: _buildIconWithBadge(index, icon, isActive),
            ),
            const SizedBox(height: 4),
            AnimatedOpacity(
              opacity: isActive ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: AnimatedSlide(
                offset: isActive ? Offset.zero : const Offset(0, 0.3),
                duration: const Duration(milliseconds: 250),
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            // Punto de brillo bajo pestaña activa
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(top: 2),
              width: isActive ? 4 : 0,
              height: isActive ? 4 : 0,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.6),
                          blurRadius: 6,
                        ),
                      ]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconWithBadge(int index, IconData icon, bool isActive) {
    final iconWidget = Icon(
      icon,
      size: 24,
      color: isActive ? AppTheme.primary : const Color(0xFF8B8BA3),
    );

    // Badge inteligente solo en Home (representando notificaciones pendientes)
    if (index == 0) {
      final unreadCount = ref.watch(unreadNotificationCountProvider);
      return Badge(
        label: Text(unreadCount.toString(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
        isLabelVisible: unreadCount > 0,
        backgroundColor: AppTheme.primary,
        textColor: Colors.black,
        smallSize: 8,
        child: iconWidget,
      );
    }

    return iconWidget;
  }

  Widget _buildFab() {
    return GestureDetector(
      onTapDown: (_) => _fabController.forward(),
      onTapUp: (_) {
        _fabController.reverse();
        HapticFeedback.mediumImpact();
        widget.onCreatePressed();
      },
      onTapCancel: () => _fabController.reverse(),
      child: AnimatedBuilder(
        animation: _fabScale,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabScale.value,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.15),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF0A0A0F),
                size: 32,
              ),
            ),
          );
        },
      ),
    );
  }
}
