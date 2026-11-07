import 'package:flutter/material.dart';
import 'package:flutter_application_3_11/app.dart';
import 'package:flutter_application_3_11/data/db/hive_setup.dart';
import 'package:flutter_application_3_11/data/models/app_settings.dart';
import 'package:flutter_application_3_11/data/repositories/settings_repository.dart';
import 'package:flutter_application_3_11/providers/repository_providers.dart';
import 'package:flutter_application_3_11/providers/tasks_provider.dart';
import 'package:flutter_application_3_11/ui/board/kanban_board.dart';
import 'package:flutter_application_3_11/ui/board/kanban_rows.dart';
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

  SegmentedButton<T> segmented<T>(WidgetTester tester) =>
      tester.widget<SegmentedButton<T>>(find.byType(SegmentedButton<T>));

  testWidgets('switches are shown directly on the Settings screen', (
    tester,
  ) async {
    await pumpApp(tester);
    await openSettings(tester);

    // Every option is visible without opening anything.
    for (final label in ['System', 'Light', 'Dark', 'Rows', 'Columns']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.byType(Dialog), findsNothing);
    expect(segmented<ThemeMode>(tester).selected, {ThemeMode.system});
    expect(segmented<BoardLayout>(tester).selected, {BoardLayout.rows});
    expect(
      find.text('Follows your phone\'s light or dark setting.'),
      findsOneWidget,
    );
    expect(
      find.text('Each status is a row. Swipe cards sideways.'),
      findsOneWidget,
    );

    // Headers and option labels are exposed to screen readers.
    expect(find.bySemanticsLabel(RegExp('Theme')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('Dark')), findsWidgets);
  });

  testWidgets('theme switch applies with one tap and saves the choice', (
    tester,
  ) async {
    await pumpApp(tester);
    await openSettings(tester);
    expect(appThemeMode(tester), ThemeMode.system);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(appThemeMode(tester), ThemeMode.dark);
    expect(segmented<ThemeMode>(tester).selected, {ThemeMode.dark});
    expect(find.text('Always dark.'), findsOneWidget);
    expect(SettingsRepository(boxes.settings).load().themeMode, ThemeMode.dark);

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

  testWidgets('board layout switch changes the board and is saved', (
    tester,
  ) async {
    await pumpApp(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TaskTrackerApp)),
    );
    await container.read(tasksProvider.notifier).add(title: 'Task');
    await tester.pumpAndSettle();
    expect(find.byType(KanbanRows), findsOneWidget);

    await openSettings(tester);
    await tester.tap(find.text('Columns'));
    await tester.pumpAndSettle();

    expect(segmented<BoardLayout>(tester).selected, {BoardLayout.columns});
    expect(
      SettingsRepository(boxes.settings).load().boardLayout,
      BoardLayout.columns,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Board'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(KanbanBoard), findsOneWidget);
    expect(find.byType(KanbanRows), findsNothing);
  });
}
