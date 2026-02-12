import 'package:flutter/material.dart';
import 'screens/grow_profile.dart';
import 'screens/climate_analytics.dart';
import 'screens/chat_dr_aurora.dart';
import 'screens/feed_pulse.dart';
import 'screens/dashboard.dart';

void main() {
  runApp(const AuroraApp());
}

class AuroraApp extends StatelessWidget {
  const AuroraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aurora (Stub)',
      theme: ThemeData.dark(),
      home: const DashboardScreen(),
    );
  }
}
