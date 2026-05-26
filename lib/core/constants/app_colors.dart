// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Purple Gradient Colors
  static const Color primaryStart = Color(0xFF6C3CE1);
  static const Color primaryEnd = Color(0xFF9B5CFF);
  static const Color primaryMid = Color(0xFF8247EE);

  // Accent
  static const Color accent = Color(0xFFFF6B8A);
  static const Color accentGold = Color(0xFFFFD166);

  // Light Mode
  static const Color lightBackground = Color(0xFFF8F7FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1035);
  static const Color lightTextSecondary = Color(0xFF6B6880);
  static const Color lightBorder = Color(0xFFE8E4F0);
  static const Color lightInputBg = Color(0xFFF4F2FA);

  // Dark Mode
  static const Color darkBackground = Color(0xFF0D0B1A);
  static const Color darkSurface = Color(0xFF1A1635);
  static const Color darkCard = Color(0xFF221E3A);
  static const Color darkTextPrimary = Color(0xFFF0EEFF);
  static const Color darkTextSecondary = Color(0xFF9B97B5);
  static const Color darkBorder = Color(0xFF2E2A4A);
  static const Color darkInputBg = Color(0xFF1E1A32);

  // Status
  static const Color success = Color(0xFF4CAF82);
  static const Color error = Color(0xFFFF4E6A);
  static const Color warning = Color(0xFFFFB347);

  // Social
  static const Color googleBg = Color(0xFFFFFFFF);
  static const Color appleBg = Color(0xFF000000);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryStart, primaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF0D0B1A), Color(0xFF2D1B6E), Color(0xFF6C3CE1)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF8247EE), Color(0xFF5E2BC5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get darkOverlay => LinearGradient(
    colors: [
      Colors.transparent,
      Colors.black.withOpacity(0.7),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}