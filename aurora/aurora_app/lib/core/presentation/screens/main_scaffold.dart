
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/widgets/aurora_bottom_nav.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/grow');
        break;
      case 2:
        // CREATE POST via FAB - Handled by onCreatePressed
        break;
      case 3:
        context.go('/social'); // Assuming Pulse maps to Social/Feed for now
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: AuroraBottomNav(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
        onCreatePressed: () {
            context.push('/create-post');
        },
      ),
    );
  }
}
