
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_theme.dart';

typedef OnTabSelected = void Function(int index);

class AuroraBottomNav extends StatefulWidget {
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
  State<AuroraBottomNav> createState() => _AuroraBottomNavState();
}

class _AuroraBottomNavState extends State<AuroraBottomNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _fabScale = Tween<double>(begin: 1.0, end: 0.9).animate(
        CurvedAnimation(parent: _fabController, curve: Curves.easeInOut));
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
            color: AppTheme.surface.withOpacity(0.8),
            border: Border(top: BorderSide(color: AppTheme.glassBorder, width: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTab(0, Icons.dashboard_rounded, 'Home'),
              _buildTab(1, Icons.eco_rounded, 'Grow'),
              _buildFab(),
              _buildTab(3, Icons.show_chart_rounded, 'Pulse'),
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
            Icon(icon,
                size: 26,
                color: isActive ? AppTheme.primary : const Color(0xFF8B8BA3)),
            const SizedBox(height: 4),
            if (isActive)
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                    color: AppTheme.primary, shape: BoxShape.circle),
              )
          ],
        ),
      ),
    );
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
      child: ScaleTransition(
        scale: _fabScale,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: AppTheme.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.black, size: 30),
        ),
      ),
    );
  }
}
