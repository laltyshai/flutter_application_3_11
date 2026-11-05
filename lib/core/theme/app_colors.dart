import 'package:flutter/material.dart';

/// Brand palette from the README.
abstract final class AppColors {
  // Primary accent: soft pastel pink.
  static const pink = Color(0xFFF4C2C2);
  static const pinkStrong = Color(0xFFFFB7B2);

  // Secondary accent: soft pastel blue.
  static const blue = Color(0xFFAEC6CF);
  static const blueStrong = Color(0xFFB3C5FF);

  // Backgrounds.
  static const offWhite = Color(0xFFF8F9FA);
  static const darkBackground = Color(0xFF1E1E24);
  static const darkSurface = Color(0xFF2A2A32);

  // Text & borders.
  static const charcoal = Color(0xFF1A1A1A);
  static const white = Color(0xFFFFFFFF);

  // Priority indicators.
  static const priorityHigh = Color(0xFFE57373);
  static const priorityMedium = Color(0xFFFFCC80);
  static const priorityLow = Color(0xFFA5D6A7);
}
