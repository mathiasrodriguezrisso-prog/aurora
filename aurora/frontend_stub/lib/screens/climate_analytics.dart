import 'package:flutter/material.dart';

class ClimateAnalyticsScreen extends StatelessWidget {
  const ClimateAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Climate Analytics')),
      body: Center(child: Text('VPD Heatmap and charts (stub)')),
    );
  }
}
