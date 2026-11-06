import 'dart:math';

import 'package:flutter_application_3_11/data/models/board_filter.dart';
import 'package:flutter_application_3_11/data/models/task.dart';
import 'package:flutter_application_3_11/providers/board_provider.dart';
import 'package:flutter_application_3_11/providers/repository_providers.dart';
import 'package:flutter_application_3_11/providers/settings_provider.dart';
import 'package:flutter_application_3_11/providers/tasks_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_hive.dart';

void main() {
  late TestHive hive;
  late ProviderContainer container;
  final now = DateTime(2026, 11, 5, 9);

  setUp(() async {
    hive = await TestHive.open();
    container = ProviderContainer(
      overrides: [
        hiveBoxesProvider.overrideWithValue(hive.boxes),
        clockProvider.overrideWithValue(() => now),
        randomProvider.overrideWithValue(Random(1)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await hive.dispose();
  });

  TasksNotifier tasks() => container.read(tasksProvider.notifier);
  BoardFilterNotifier filter() => container.read(boardFilterProvider.notifier);
  List<String> titles(List<Task> list) => [for (final t in list) t.title];

  test('columns split board tasks by status; Messy Can is left out', () async {
    await tasks().add(title: 'todo');
    await tasks().add(title: 'doing', status: TaskStatus.inProgress);
    await tasks().add(title: 'done', status: TaskStatus.done);
    await tasks().add(title: 'idea', status: TaskStatus.messyCan);

    final columns = container.read(boardColumnsProvider);
    expect(columns.keys, TaskStatus.boardColumns);
    expect(titles(columns[TaskStatus.todo]!), ['todo']);
    expect(titles(columns[TaskStatus.inProgress]!), ['doing']);
    expect(titles(columns[TaskStatus.done]!), ['done']);
    expect(container.read(boardHasTasksProvider), isTrue);
  });

  test('only Messy Can tasks means the board is empty', () async {
    await tasks().add(title: 'idea', status: TaskStatus.messyCan);
    expect(container.read(boardHasTasksProvider), isFalse);
  });

  test('filter notifier toggles values and clears them', () async {
    await tasks().add(title: 'high', priority: TaskPriority.high);
    await tasks().add(title: 'low', priority: TaskPriority.low);

    filter().togglePriority(TaskPriority.high);
    expect(container.read(boardFilterProvider).priorities, {TaskPriority.high});
    expect(titles(container.read(boardColumnsProvider)[TaskStatus.todo]!), [
      'high',
    ]);

    filter().togglePriority(TaskPriority.high);
    expect(container.read(boardFilterProvider).hasFilters, isFalse);

    filter()
      ..toggleLabel('x')
      ..toggleCategory('Work')
      ..setSort(TaskSortField.priority)
      ..setAscending(true)
      ..clearFilters();
    expect(
      container.read(boardFilterProvider),
      BoardFilter(sortField: TaskSortField.priority, ascending: true),
    );
  });

  test('filter options merge settings with values used on tasks', () async {
    await container.read(settingsProvider.notifier).addLabel('zeta');
    await tasks().add(title: 'a', category: 'Garden', labels: ['Alpha']);
    await tasks().add(
      title: 'idea',
      status: TaskStatus.messyCan,
      labels: ['hidden'],
    );

    final options = container.read(boardFilterOptionsProvider);
    expect(options.labels, ['Alpha', 'zeta']);
    expect(options.categories, containsAll(['Garden', 'Work', 'Personal']));
  });

  group('next task picker', () {
    test('picks only pending tasks that match the filters', () async {
      await tasks().add(title: 'work todo', category: 'Work');
      await tasks().add(
        title: 'work doing',
        category: 'Work',
        status: TaskStatus.inProgress,
      );
      await tasks().add(
        title: 'work done',
        category: 'Work',
        status: TaskStatus.done,
      );
      await tasks().add(title: 'chores', category: 'Chores');
      filter().toggleCategory('Work');

      final picker = container.read(nextTaskPickerProvider);
      expect(
        titles(picker.candidates),
        unorderedEquals(['work todo', 'work doing']),
      );
      for (var i = 0; i < 20; i++) {
        expect(picker.pick()!.title, startsWith('work '));
        expect(picker.pick()!.status, isNot(TaskStatus.done));
      }
    });

    test('pick again avoids the previous task', () async {
      final a = await tasks().add(title: 'a');
      await tasks().add(title: 'b');

      final picker = container.read(nextTaskPickerProvider);
      for (var i = 0; i < 20; i++) {
        expect(picker.pick(excludeId: a.id)!.title, 'b');
      }
    });

    test('nothing to pick gives null', () async {
      await tasks().add(title: 'done', status: TaskStatus.done);
      expect(container.read(nextTaskPickerProvider).pick(), isNull);
    });
  });
}
