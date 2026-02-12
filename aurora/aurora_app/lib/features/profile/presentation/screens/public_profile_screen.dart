
import 'package:flutter/material.dart';
import '../../../../core/config/app_theme.dart';

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primary,
              child: Icon(Icons.person, size: 40, color: Colors.black),
            ),
            const SizedBox(height: 16),
            const Text('Another Grower', style: TextStyle(color: Colors.white, fontSize: 20)),
             Text('Coming Soon', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }
}
