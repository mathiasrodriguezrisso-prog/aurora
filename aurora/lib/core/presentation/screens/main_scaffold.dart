/// 📁 lib/core/presentation/screens/main_scaffold.dart
/// Scaffold raíz que gestiona la navegación entre ramas de pestañas
/// y coordina el Bottom Navigation Bar de 5 posiciones.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/aurora_bottom_nav.dart';

class MainScaffold extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  void _onTabSelected(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _onCreatePressed() {
    // Ruta alineada con feed/create
    context.push('/feed/create');
  }

  @override
  Widget build(BuildContext context) {
    // Mapeo para 5 pestañas: Home(0), Grow(1), FAB(2), Feed(3), Profile(4)
    // Shell Branches: 0=Home, 1=Grow, 2=Feed, 3=Profile
    final shellIndex = widget.navigationShell.currentIndex;
    final navIndex = shellIndex >= 2 ? shellIndex + 1 : shellIndex;

    return Scaffold(
      backgroundColor: Colors.black,
      body: widget.navigationShell,
      extendBody: true,
      bottomNavigationBar: AuroraBottomNav(
        currentIndex: navIndex,
        onTabSelected: (navIdx) {
          if (navIdx == 2) return; // FAB manejado por onCreatePressed
          final branchIdx = navIdx > 2 ? navIdx - 1 : navIdx;
          _onTabSelected(branchIdx);
        },
        onCreatePressed: _onCreatePressed,
      ),
    );
  }
}
