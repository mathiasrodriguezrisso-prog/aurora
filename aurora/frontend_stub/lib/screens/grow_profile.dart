import 'package:flutter/material.dart';

class GrowProfileScreen extends StatelessWidget {
  const GrowProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grower Profile')),
      body: Center(child: Text('Karma / Level / Harvest History (stub)')),
    );
  }
}
