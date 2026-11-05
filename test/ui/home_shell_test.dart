import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_3_11/app.dart';
import 'package:flutter_application_3_11/core/theme/app_colors.dart';
import 'package:flutter_application_3_11/core/theme/app_theme.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TaskTrackerApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('starts on the Board tab', (tester) async {
    await pumpApp(tester);

    expect(find.widgetWithText(AppBar, 'Board'), findsOneWidget);
    expect(find.text('No tasks yet'), findsOneWidget);
  });

  testWidgets('switches between the four tabs', (tester) async {
    await pumpApp(tester);

    const tabs = {
      'Calendar': 'Nothing scheduled',
      'Messy Can': 'The can is empty',
      'Backup': 'Backup & restore',
      'Board': 'No tasks yet',
    };

    for (final MapEntry(key: label, value: emptyTitle) in tabs.entries) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, label), findsOneWidget, reason: label);
      expect(find.text(emptyTitle), findsOneWidget, reason: label);
    }
  });

  test('themes use the brand font and palette', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();

    expect(light.textTheme.bodyMedium?.fontFamily, AppTheme.fontFamily);
    expect(dark.textTheme.bodyMedium?.fontFamily, AppTheme.fontFamily);
    expect(light.scaffoldBackgroundColor, AppColors.offWhite);
    expect(dark.scaffoldBackgroundColor, AppColors.darkBackground);
    expect(light.colorScheme.primary, AppColors.pinkStrong);
    expect(light.colorScheme.secondary, AppColors.blueStrong);
    expect(light.colorScheme.onSurface, AppColors.charcoal);
  });
}
