
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../core/config/app_router.dart'; // import app_router to navigate
import '../providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait for animation
    await Future.delayed(const Duration(seconds: 2));

    // Check session
    final notifier = ref.read(authProvider.notifier);
    await notifier.checkSession();
    
    // Check onboarding
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    final authState = ref.read(authProvider);

    if (!mounted) return;

    if (authState.status == AuthStatus.authenticated) {
      context.go('/home');
    } else {
      if (onboardingComplete) {
        context.go('/login');
      } else {
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo / Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  )
                ],
              ),
              child: const Icon(
                Icons.eco_rounded,
                size: 80,
                color: AppTheme.primary,
              ),
            ).animate().fadeIn(duration: 1.seconds).scale(),
            
            const SizedBox(height: 20),
            
            // Title
            ShaderMask(
              shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
              child: const Text(
                'AURORA',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 800.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 10),
            
            // Subtitle
            const Text(
              'AI-Powered Cannabis Companion',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ).animate().fadeIn(delay: 1.seconds, duration: 800.ms),
          ],
        ),
      ),
    );
  }
}
