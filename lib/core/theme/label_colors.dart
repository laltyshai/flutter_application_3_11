import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Colors for task labels. Each label looks "randomly" colored, but the
/// color comes from a hash of its name, so it is the same on every card,
/// every screen and every app start (and for "Home" and "home").
abstract final class LabelColors {
  /// Background color for [label].
  static Color of(String label) {
    final palette = AppColors.labelPalette;
    return palette[_hash(label.trim().toLowerCase()) % palette.length];
  }

  /// Text color that reads best on [background]: charcoal or white,
  /// whichever has the higher contrast ratio.
  static Color onColor(Color background) {
    final bg = background.computeLuminance();
    final onDark = _contrast(AppColors.white.computeLuminance(), bg);
    final onLight = _contrast(AppColors.charcoal.computeLuminance(), bg);
    return onDark >= onLight ? AppColors.white : AppColors.charcoal;
  }

  static double _contrast(double a, double b) =>
      (a > b ? a + 0.05 : b + 0.05) / (a > b ? b + 0.05 : a + 0.05);

  /// FNV-1a (32-bit). Unlike `String.hashCode`, it is stable across Dart
  /// versions and platforms, so colors never shuffle after an update.
  static int _hash(String s) {
    var h = 0x811C9DC5;
    for (final unit in s.codeUnits) {
      h ^= unit;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h;
  }
}
