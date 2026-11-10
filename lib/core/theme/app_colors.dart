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

  // Label colors (GitHub-style). A label always gets the same one, picked
  // from its name by [LabelColors.of].
  static const labelPalette = [
    Color(0xFFD73A4A), // red
    Color(0xFF0075CA), // blue
    Color(0xFFA2EEEF), // cyan
    Color(0xFF7057FF), // purple
    Color(0xFF008672), // teal
    Color(0xFFE4E669), // yellow
    Color(0xFFD876E3), // pink
    Color(0xFFFBCA04), // amber
    Color(0xFF0E8A16), // green
    Color(0xFF1D76DB), // azure
    Color(0xFFB60205), // dark red
    Color(0xFF5319E7), // violet
    Color(0xFFF9D0C4), // peach
    Color(0xFFC2E0C6), // mint
    Color(0xFFBFDADC), // slate
    Color(0xFFFEF2C0), // cream
  ];
}
