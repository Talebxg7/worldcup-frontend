import 'package:flutter/material.dart';

class AppColors {
  // Primary - Vibrant Green (Football/FIFA green)
  static const Color primary = Color(0xFF00C853);
  static const Color primaryLight = Color(0xFF5EFC82);
  static const Color primaryDark = Color(0xFF009624);

  // Secondary - Electric Blue
  static const Color secondary = Color(0xFF2979FF);
  static const Color secondaryLight = Color(0xFF75A7FF);
  static const Color secondaryDark = Color(0xFF004ECB);

  // Accent - Golden Trophy
  static const Color accent = Color(0xFFFFD600);
  static const Color accentLight = Color(0xFFFFFF52);
  static const Color accentDark = Color(0xFFC7A500);

  // Score colors
  static const Color exactScore = Color(0xFF00C853);   // 3 pts - green
  static const Color correctResult = Color(0xFF2979FF); // 1 pt - blue
  static const Color wrongResult = Color(0xFFFF1744);   // 0 pts - red

  // Rank colors
  static const Color gold = Color(0xFFFFD600);
  static const Color silver = Color(0xFFB0BEC5);
  static const Color bronze = Color(0xFFFF6D00);

  // Light Theme
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightDivider = Color(0xFFE5E7EB);
  static const Color lightBorder = Color(0xFFD1D5DB);

  // Dark Theme
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF21262D);
  static const Color darkTextPrimary = Color(0xFFF0F6FC);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  static const Color darkDivider = Color(0xFF30363D);
  static const Color darkBorder = Color(0xFF30363D);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C853), Color(0xFF2979FF)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD600), Color(0xFFFF6D00)],
  );

  static const LinearGradient darkHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF009624), Color(0xFF004ECB)],
  );
}
