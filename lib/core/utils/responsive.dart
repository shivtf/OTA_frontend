// lib/core/utils/responsive.dart
import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double hp(BuildContext context, double percent) =>
      screenHeight(context) * percent / 100;

  static double wp(BuildContext context, double percent) =>
      screenWidth(context) * percent / 100;

  static bool isSmallScreen(BuildContext context) =>
      screenWidth(context) < 360;

  static bool isMediumScreen(BuildContext context) =>
      screenWidth(context) >= 360 && screenWidth(context) < 414;

  static bool isLargeScreen(BuildContext context) =>
      screenWidth(context) >= 414;

  static double adaptivePadding(BuildContext context) {
    if (isSmallScreen(context)) return 16.0;
    if (isMediumScreen(context)) return 20.0;
    return 24.0;
  }

  static double adaptiveFontSize(BuildContext context, double size) {
    final scale = screenWidth(context) / 390;
    return size * scale.clamp(0.85, 1.2);
  }
}