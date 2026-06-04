import 'package:flutter/material.dart';

class AppColors {
  // Quantum Theme
  static const Color backgroundDark = Color(0xFF05050B);
  static const Color neonPurple = Color(0xFF9D00FF);
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonPink = Color(0xFFFF003C);
  
  static const Color surface = Color(0x1AFFFFFF); // Glass
  static const Color surfaceHighlight = Color(0x33FFFFFF);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C0);
  
  static const Color error = neonPink;
  static const Color secondary = neonCyan;
  static const Color primary = neonPurple;

  static const LinearGradient quantumGradient = LinearGradient(
    colors: [neonPurple, neonCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
