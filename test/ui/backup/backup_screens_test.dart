import 'package:flutter/material.dart';
import 'package:flutter_application_3_11/core/theme/app_theme.dart';
import 'package:flutter_application_3_11/data/db/hive_setup.dart';
import 'package:flutter_application_3_11/data/models/backup_data.dart';
import 'package:flutter_application_3_11/data/models/task.dart';
import 'package:flutter_application_3_11/data/services/backup_codec.dart';
import 'package:flutter_application_3_11/providers/backup_provider.dart';
import 'package:flutter_application_3_11/providers/repository_providers.dart';
import 'package:flutter_application_3_11/providers/tasks_provider.dart';
import 'package:flutter_application_3_11/ui/backup/backup_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_backup_io.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_hive.dart';

void main() {
  late HiveBoxes boxes;
  late FakeBackupFileStore store;
  late FakeBackupSharer sharer;
  late FakeBackupFilePicker picker;

  setUp(() async {
    boxes = await openMemoryHive();
    store = FakeBackupFileStore();
    sharer = FakeBackupSharer();
    picker = FakeBackupFilePicker(null);
  });
  tearDown(() => closeMemoryHive(boxes));

  Future<ProviderContainer> pumpBackup(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        hiveBoxesProvider.overrideWithValue(boxes),
        clockProvider.overrideWithValue(() => testNow),
        backupFileStoreProvider.overrideWithValue(store),
        backupSharerProvider.overrideWithValue(sharer),
        backupFilePickerProvider.overrideWithValue(picker),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light(), home: const BackupScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  String backupWith(List<Task> tasks) => BackupFormat.json.codec.encode(
    BackupData(schemaVersion: 1, exportedAt: testNow, tasks: tasks),
  );

  Future<void> openImport(WidgetTester tester) =>
      tapVisible(tester, find.text('Import backup'));

  testWidgets('export: save as CSV and share as JSON', (tester) async {
    final container = await pumpBackup(tester);
    await container.read(tasksProvider.notifier).add(title: 'One');
    await tester.pumpAndSettle();
    expect(find.text('Tasks: 1 · Ideas: 0'), findsOneWidget);

    await tester.tap(find.text('CSV'));
    await tester.pumpAndSettle();
    expect(find.text(BackupFormat.csv.description), findsOneWidget);
    await tapVisible(tester, find.text('Save to device'));
    expect(
      find.text('Saved to /docs/task_tracker_2026-11-05_0900.csv'),
      findsOneWidget,
    );
    expect(store.files.values.single, contains('One'));

    await tester.tap(find.text('JSON'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Share'));
    expect(sharer.shared.single.mimeType, 'application/json');
  });

  testWidgets('import: bad paste shows an error', (tester) async {
    await pumpBackup(tester);
    await openImport(tester);

    await tester.enterText(find.byType(TextField), '{"nope": true}');
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not read the backup: Missing schemaVersion'),
      findsOneWidget,
    );
    expect(find.text('Merge'), findsNothing);

    // Editing the text clears the stale error.
    await tester.enterText(find.byType(TextField), '{');
    await tester.pump();
    expect(find.textContaining('Could not read'), findsNothing);
  });

  testWidgets('import: paste → preview → merge', (tester) async {
    final container = await pumpBackup(tester);
    final existing = await container
        .read(tasksProvider.notifier)
        .add(title: 'Existing');
    await tester.pumpAndSettle();
    await openImport(tester);

    final incoming = Task.create(title: 'Imported', now: testNow);
    await tester.enterText(
      find.byType(TextField),
      backupWith([existing, incoming]),
    );
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('2 tasks, 1 new, 1 existing'), findsOneWidget);

    await tapVisible(tester, find.widgetWithText(FilledButton, 'Merge'));
    expect(find.text('Backup merged into your data'), findsOneWidget);
    expect(find.text('Import backup'), findsOneWidget); // back on Backup tab
    expect(
      {for (final t in container.read(tasksProvider)) t.title},
      {'Existing', 'Imported'},
    );
  });

  testWidgets('import: pick file → restore asks first, then replaces', (
    tester,
  ) async {
    final container = await pumpBackup(tester);
    await container.read(tasksProvider.notifier).add(title: 'Will be gone');
    await tester.pumpAndSettle();
    picker.text = backupWith([Task.create(title: 'Restored', now: testNow)]);
    await openImport(tester);

    await tester.tap(find.text('Pick file'));
    await tester.pumpAndSettle();
    expect(find.text('1 task, 1 new, 0 existing'), findsOneWidget);
    expect(find.textContaining('"Restored"'), findsOneWidget); // text filled

    final restore = find.widgetWithText(TextButton, 'Restore');
    await tapVisible(tester, restore);
    expect(find.text('Replace all data?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(container.read(tasksProvider).single.title, 'Will be gone');

    await tapVisible(tester, restore);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, 'Restore'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Backup restored'), findsOneWidget);
    expect(container.read(tasksProvider).single.title, 'Restored');
  });
}
