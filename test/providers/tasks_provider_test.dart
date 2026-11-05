import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_application_3_11/data/models/subtask.dart';
import 'package:flutter_application_3_11/data/models/task.dart';
import 'package:flutter_application_3_11/data/repositories/task_repository.dart';
import 'package:flutter_application_3_11/providers/repository_providers.dart';
import 'package:flutter_application_3_11/providers/settings_provider.dart';
import 'package:flutter_application_3_11/providers/tasks_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_hive.dart';

void main() {
  late TestHive hive;
  late ProviderContainer container;
  var now = DateTime(2026, 11, 5, 9);

  setUp(() async {
    hive = await TestHive.open();
    now = DateTime(2026, 11, 5, 9);
    container = ProviderContainer(
      overrides: [
        hiveBoxesProvider.overrideWithValue(hive.boxes),
        clockProvider.overrideWithValue(() => now),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await hive.dispose();
  });

  TasksNotifier notifier() => container.read(tasksProvider.notifier);
  List<Task> tasks() => container.read(tasksProvider);

  group('TasksNotifier', () {
    test('starts with what is stored', () async {
      final stored = Task.create(title: 'stored', now: now);
      await TaskRepository(hive.boxes.tasks).upsert(stored);

      expect(tasks(), [stored]);
    });

    test('add stores a trimmed task with timestamps from the clock', () async {
      final task = await notifier().add(
        title: '  Buy milk  ',
        category: 'Chores',
      );

      expect(tasks(), [task]);
      expect(task.title, 'Buy milk');
      expect(task.createdAt, now);
      expect(container.read(taskRepositoryProvider).getById(task.id), task);
    });

    test('save bumps updatedAt but keeps createdAt', () async {
      final task = await notifier().add(title: 'A');
      now = now.add(const Duration(hours: 2));

      await notifier().save(task.copyWith(title: 'A edited'));

      final saved = tasks().single;
      expect(saved.title, 'A edited');
      expect(saved.createdAt, DateTime(2026, 11, 5, 9));
      expect(saved.updatedAt, DateTime(2026, 11, 5, 11));
    });

    test('moveTo changes status; delete removes', () async {
      final task = await notifier().add(
        title: 'Idea',
        status: TaskStatus.messyCan,
      );

      await notifier().moveTo(task.id, TaskStatus.todo);
      expect(tasks().single.status, TaskStatus.todo);

      await notifier().delete(task.id);
      expect(tasks(), isEmpty);
    });

    test('toggleSubtask flips only that subtask', () async {
      final task = await notifier().add(
        title: 'With steps',
        subtasks: const [
          Subtask(id: 's1', title: 'one'),
          Subtask(id: 's2', title: 'two'),
        ],
      );

      await notifier().toggleSubtask(task.id, 's2');

      final subtasks = tasks().single.subtasks;
      expect(subtasks[0].isDone, isFalse);
      expect(subtasks[1].isDone, isTrue);
      expect(tasks().single.subtaskRatio, '1/2');
    });

    test('picks up writes made directly to the repository', () async {
      container.listen(tasksProvider, (_, _) {});
      final external = Task.create(title: 'imported', now: now);

      await TaskRepository(hive.boxes.tasks).upsert(external);
      await pumpEventQueue();

      expect(tasks(), [external]);
    });
  });

  group('SettingsNotifier', () {
    test('changes are persisted', () async {
      final settings = container.read(settingsProvider.notifier);
      await settings.setThemeMode(ThemeMode.dark);
      await settings.addCategory('Garden');

      final stored = container.read(settingsRepositoryProvider).load();
      expect(stored.themeMode, ThemeMode.dark);
      expect(stored.categories, contains('Garden'));
    });

    test('addCategory and addLabel ignore blanks and duplicates', () async {
      final settings = container.read(settingsProvider.notifier);
      await settings.addCategory('  ');
      await settings.addCategory('work');
      await settings.addLabel('urgent');
      await settings.addLabel('URGENT');

      final state = container.read(settingsProvider);
      expect(
        state.categories.where((c) => c.toLowerCase() == 'work'),
        hasLength(1),
      );
      expect(state.labels, ['urgent']);
    });
  });
}
