import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_application_3_11/data/models/backup_data.dart';
import 'package:flutter_application_3_11/data/models/subtask.dart';
import 'package:flutter_application_3_11/data/models/task.dart';
import 'package:flutter_application_3_11/data/services/backup_codec.dart';
import 'package:flutter_application_3_11/data/services/backup_merge.dart';
import 'package:flutter_application_3_11/providers/backup_provider.dart';
import 'package:flutter_application_3_11/providers/repository_providers.dart';
import 'package:flutter_application_3_11/providers/settings_provider.dart';
import 'package:flutter_application_3_11/providers/tasks_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_backup_io.dart';
import '../helpers/test_hive.dart';

void main() {
  late TestHive hive;
  late ProviderContainer container;
  late FakeBackupFileStore store;
  late FakeBackupSharer sharer;
  late FakeBackupFilePicker picker;
  var now = DateTime(2026, 11, 5, 9);

  setUp(() async {
    hive = await TestHive.open();
    now = DateTime(2026, 11, 5, 9);
    store = FakeBackupFileStore();
    sharer = FakeBackupSharer();
    picker = FakeBackupFilePicker(null);
    container = ProviderContainer(
      overrides: [
        hiveBoxesProvider.overrideWithValue(hive.boxes),
        clockProvider.overrideWithValue(() => now),
        backupFileStoreProvider.overrideWithValue(store),
        backupSharerProvider.overrideWithValue(sharer),
        backupFilePickerProvider.overrideWithValue(picker),
      ],
    );
    // Keep the autoDispose import notifier alive between reads.
    container.listen(importProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await hive.dispose();
  });

  TasksNotifier tasks() => container.read(tasksProvider.notifier);
  ImportNotifier importer() => container.read(importProvider.notifier);
  ImportState importState() => container.read(importProvider);

  Future<void> seed() async {
    await tasks().add(
      title: 'Paint fence',
      labels: ['home'],
      dueDate: DateTime(2026, 11, 9),
      subtasks: const [Subtask(id: 's', title: 'Buy paint')],
    );
    await tasks().add(title: 'Idea', status: TaskStatus.messyCan);
    await container.read(settingsProvider.notifier).addLabel('home');
    await container
        .read(settingsProvider.notifier)
        .setThemeMode(ThemeMode.dark);
  }

  test('summary counts tasks and ideas', () async {
    await seed();
    expect(container.read(backupSummaryProvider), (tasks: 1, ideas: 1));
  });

  test('save writes a named file; share shares it', () async {
    await seed();
    final path = await container
        .read(exportProvider.notifier)
        .save(BackupFormat.json);
    expect(path, '/docs/task_tracker_2026-11-05_0900.json');
    expect(container.read(exportProvider).value, path);

    await container.read(exportProvider.notifier).share(BackupFormat.csv);
    expect(sharer.shared.single.path, endsWith('.csv'));
    expect(sharer.shared.single.mimeType, 'text/csv');
    expect(store.files.keys, hasLength(2));
  });

  for (final format in BackupFormat.values) {
    test(
      '${format.label}: export → wipe → restore gives identical data',
      () async {
        await seed();
        final before = [...container.read(tasksProvider)];
        final settingsBefore = container.read(settingsProvider);
        final path = await container.read(exportProvider.notifier).save(format);

        await tasks().replaceAll(const []);
        expect(container.read(tasksProvider), isEmpty);

        importer().load(store.files[path]!);
        expect(importState().preview!.newCount, before.length);
        await importer().apply(ImportMode.restore);

        expect(importState().applied, ImportMode.restore);
        expect(container.read(tasksProvider), unorderedEquals(before));
        expect(container.read(settingsProvider), settingsBefore);
      },
    );
  }

  test('invalid text sets an error and writes nothing', () async {
    await seed();
    final before = [...container.read(tasksProvider)];

    importer().load('   ');
    expect(importState().error, contains('Paste a backup'));
    importer().load('{"schemaVersion":1,"tasks":[{"id":"x"}]}');
    expect(
      importState().error,
      startsWith('Could not read the backup: Task 1'),
    );
    expect(importState().canApply, isFalse);

    await importer().apply(ImportMode.restore); // no data → no-op
    expect(container.read(tasksProvider), before);

    importer().clear();
    expect(importState().error, isNull);
  });

  test('merge adds new tasks, updates newer ones and keeps the rest', () async {
    final mine = await tasks().add(title: 'Mine');
    final shared = await tasks().add(title: 'Shared old');
    final newer = shared.copyWith(
      title: 'Shared new',
      updatedAt: now.add(const Duration(days: 1)),
    );
    final fresh = Task.create(title: 'From backup', now: now);
    final text = BackupFormat.json.codec.encode(
      BackupData(schemaVersion: 1, exportedAt: now, tasks: [newer, fresh]),
    );

    importer().load(text);
    expect(importState().preview!.summary, '2 tasks, 1 new, 1 existing');
    expect(importState().preview!.newerCount, 1);
    await importer().apply(ImportMode.merge);

    final titles = {for (final t in container.read(tasksProvider)) t.title};
    expect(titles, {'Mine', 'Shared new', 'From backup'});
    expect(tasks().byId(mine.id), mine);
    // Applying twice is blocked.
    expect(importState().canApply, isFalse);
  });

  test('pickFile loads the picked text; cancel leaves state empty', () async {
    expect(await importer().pickFile(), isNull);
    expect(importState().data, isNull);
    expect(importState().busy, isFalse);

    picker.text = 'id,title,createdAt\nx,From file,2026-11-01';
    await importer().pickFile();
    expect(importState().preview!.summary, '1 task, 1 new, 0 existing');
  });
}
