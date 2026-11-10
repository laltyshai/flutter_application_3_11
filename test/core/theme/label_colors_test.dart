import 'package:flutter/painting.dart';
import 'package:flutter_application_3_11/core/theme/app_colors.dart';
import 'package:flutter_application_3_11/core/theme/label_colors.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('a label always gets the same palette color', () {
    final c = LabelColors.of('urgent');
    expect(AppColors.labelPalette, contains(c));
    expect(LabelColors.of('urgent'), c);
    expect(LabelColors.of(' URGENT '), c); // case and spaces ignored
  });

  test('different labels spread over the palette', () {
    final colors = {
      for (final l in [
        'home',
        'work',
        'urgent',
        'bug',
        'idea',
        'diy',
        'shopping',
        'health',
        'money',
        'study',
        'travel',
        'family',
      ])
        LabelColors.of(l),
    };
    expect(colors.length, greaterThanOrEqualTo(6));
  });

  test('known labels keep their color (hash is stable)', () {
    // Guards against a hash change that would recolor everyone's labels.
    expect(LabelColors.of('home'), LabelColors.of('Home'));
    expect(LabelColors.of(''), AppColors.labelPalette[0x811C9DC5 % 16]);
  });

  test('text on every label color is readable (WCAG AA, 4.5:1)', () {
    for (final bg in AppColors.labelPalette) {
      final fg = LabelColors.onColor(bg);
      expect(
        contrast(fg, bg),
        greaterThanOrEqualTo(4.5),
        reason: 'text on ${bg.toARGB32().toRadixString(16)}',
      );
    }
  });

  test('picks white on dark colors and charcoal on light ones', () {
    expect(LabelColors.onColor(const Color(0xFFB60205)), AppColors.white);
    expect(LabelColors.onColor(const Color(0xFFFEF2C0)), AppColors.charcoal);
  });
}
