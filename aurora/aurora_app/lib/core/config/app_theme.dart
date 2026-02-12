
import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const primary = Color(0xFF00E676); // Emerald Green
  static const secondary = Color(0xFF9C27B0); // Deep Purple
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const error = Color(0xFFCF6679);

  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white70;

  // Glassmorphism
  static final glassBackground = Colors.white.withOpacity(0.05);
  static final glassBorder = Colors.white.withOpacity(0.1);

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF69F0AE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      // Define other theme properties as needed
    );
  }
}
