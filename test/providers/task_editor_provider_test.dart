import 'package:flutter_application_3_11/data/db/hive_setup.dart';
import 'package:flutter_application_3_11/data/models/task.dart';
import 'package:flutter_application_3_11/providers/repository_providers.dart';
import 'package:flutter_application_3_11/providers/settings_provider.dart';
import 'package:flutter_application_3_11/providers/task_editor_provider.dart';
import 'package:flutter_application_3_11/providers/tasks_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_hive.dart';

void main() {
  late HiveBoxes boxes;
  late ProviderContainer container;
  var now = DateTime(2026, 11, 5, 9);

  setUp(() async {
    boxes = await openMemoryHive();
    now = DateTime(2026, 11, 5, 9);
    container = ProviderContainer(
      overrides: [
        hiveBoxesProvider.overrideWithValue(boxes),
        clockProvider.overrideWithValue(() => now),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await closeMemoryHive(boxes);
  });

  const newArgs = TaskEditorArgs.create();

  TaskEditorNotifier editor(TaskEditorArgs args) {
    // Keep the autoDispose provider alive for the whole test.
    container.listen(taskEditorProvider(args), (_, _) {});
    return container.read(taskEditorProvider(args).notifier);
  }

  TaskEditorState stateOf(TaskEditorArgs args) =>
      container.read(taskEditorProvider(args));

  group('new task', () {
    test('uses presets and the first category', () {
      final args = TaskEditorArgs.create(
        initialStatus: TaskStatus.messyCan,
        initialDueDate: DateTime(2026, 11, 7),
      );
      editor(args);

      final s = stateOf(args);
      expect(s.isNew, isTrue);
      expect(s.draft.status, TaskStatus.messyCan);
      expect(s.draft.dueDate, DateTime(2026, 11, 7));
      expect(s.draft.category, 'Work');
      expect(s.isDirty, isFalse);
    });

    test('cannot save without a title', () async {
      final e = editor(newArgs);
      expect(stateOf(newArgs).canSave, isFalse);

      e.setTitle('   ');
      expect(stateOf(newArgs).canSave, isFalse);
      expect(await e.save(), isFalse);
      expect(container.read(tasksProvider), isEmpty);
    });

    test('labels: trimmed, no duplicates, removable', () {
      final e = editor(newArgs)
        ..addLabel(' urgent ')
        ..addLabel('URGENT')
        ..addLabel('')
        ..addLabel('home');
      expect(stateOf(newArgs).draft.labels, ['urgent', 'home']);

      e.removeLabel('urgent');
      expect(stateOf(newArgs).draft.labels, ['home']);
    });

    test('subtasks: add, toggle, remove', () {
      final e = editor(newArgs)
        ..addSubtask('one')
        ..addSubtask('  ')
        ..addSubtask('two');
      final subtasks = stateOf(newArgs).draft.subtasks;
      expect(subtasks.map((s) => s.title), ['one', 'two']);

      e.toggleSubtask(subtasks.first.id);
      expect(stateOf(newArgs).draft.subtaskRatio, '1/2');

      e.removeSubtask(subtasks.last.id);
      expect(stateOf(newArgs).draft.subtasks, hasLength(1));
    });

    test('save creates the task and remembers labels and category', () async {
      final e = editor(newArgs)
        ..setTitle('  Plan trip ')
        ..setDescription('Book hotel ')
        ..setPriority(TaskPriority.high)
        ..setCategory('Travel')
        ..addLabel('summer')
        ..setDueDate(DateTime(2026, 12, 1))
        ..addSubtask('Flights');
      expect(stateOf(newArgs).isDirty, isTrue);

      expect(await e.save(), isTrue);

      final task = container.read(tasksProvider).single;
      expect(task.title, 'Plan trip');
      expect(task.description, 'Book hotel');
      expect(task.priority, TaskPriority.high);
      expect(task.category, 'Travel');
      expect(task.labels, ['summer']);
      expect(task.dueDate, DateTime(2026, 12, 1));
      expect(task.subtasks.single.title, 'Flights');
      expect(task.createdAt, now);
      expect(stateOf(newArgs).isDirty, isFalse);

      final settings = container.read(settingsProvider);
      expect(settings.labels, contains('summer'));
      expect(settings.categories, contains('Travel'));
    });
  });

  group('existing task', () {
    late Task existing;
    late TaskEditorArgs args;

    setUp(() async {
      existing = await container
          .read(tasksProvider.notifier)
          .add(title: 'Original', labels: const ['a']);
      args = TaskEditorArgs.edit(existing.id);
    });

    test('loads the task fields', () {
      editor(args);
      final s = stateOf(args);
      expect(s.isNew, isFalse);
      expect(s.draft.title, 'Original');
      expect(s.draft.labels, ['a']);
      expect(s.canSave, isTrue);
    });

    test('save keeps id and createdAt, bumps updatedAt', () async {
      now = now.add(const Duration(hours: 3));
      final e = editor(args)..setTitle('Renamed');

      await e.save();

      final saved = container.read(tasksProvider).single;
      expect(saved.id, existing.id);
      expect(saved.title, 'Renamed');
      expect(saved.createdAt, existing.createdAt);
      expect(saved.updatedAt, now);
    });

    test('delete removes it', () async {
      await editor(args).delete();
      expect(container.read(tasksProvider), isEmpty);
    });

    test('unknown id is reported as not found', () {
      const missing = TaskEditorArgs.edit('nope');
      editor(missing);
      expect(stateOf(missing).notFound, isTrue);
      expect(stateOf(missing).canSave, isFalse);
    });
  });
}
