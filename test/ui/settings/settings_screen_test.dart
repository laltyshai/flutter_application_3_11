import 'package:flutter/material.dart';
import 'package:flutter_application_3_11/app.dart';
import 'package:flutter_application_3_11/data/db/hive_setup.dart';
import 'package:flutter_application_3_11/data/repositories/settings_repository.dart';
import 'package:flutter_application_3_11/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_hive.dart';

void main() {
  late HiveBoxes boxes;
  setUp(() async => boxes = await openMemoryHive());
  tearDown(() => closeMemoryHive(boxes));

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [hiveBoxesProvider.overrideWithValue(boxes)],
        child: const TaskTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Settings'),
      ),
    );
    await tester.pumpAndSettle();
  }

  ThemeMode appThemeMode(WidgetTester tester) =>
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

  testWidgets('Settings replaces Backup in the bottom bar', (tester) async {
    await pumpApp(tester);
    final nav = find.byType(NavigationBar);
    expect(
      find.descendant(of: nav, matching: find.text('Settings')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: nav, matching: find.text('Backup')),
      findsNothing,
    );
  });

  testWidgets('theme switch applies and saves the choice', (tester) async {
    await pumpApp(tester);
    await openSettings(tester);
    expect(appThemeMode(tester), ThemeMode.system);
    expect(find.text('System'), findsOneWidget); // tile subtitle

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(appThemeMode(tester), ThemeMode.dark);
    expect(find.text('Dark'), findsOneWidget); // subtitle updated
    expect(SettingsRepository(boxes.settings).load().themeMode, ThemeMode.dark);

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(appThemeMode(tester), ThemeMode.light);
  });

  testWidgets('saved theme is used on start', (tester) async {
    final repo = SettingsRepository(boxes.settings);
    await repo.save(repo.load().copyWith(themeMode: ThemeMode.dark));
    await pumpApp(tester);
    expect(appThemeMode(tester), ThemeMode.dark);
  });

  testWidgets('Backup button opens Backup & restore, back returns', (
    tester,
  ) async {
    await pumpApp(tester);
    await openSettings(tester);

    await tester.tap(find.text('Backup & restore'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Backup'), findsOneWidget);
    expect(find.text('Import backup'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
  });
}
