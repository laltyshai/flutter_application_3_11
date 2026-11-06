import 'dart:math';

import 'package:flutter_application_3_11/data/models/task.dart';
import 'package:flutter_application_3_11/providers/messy_can_provider.dart';
import 'package:flutter_application_3_11/providers/random_provider.dart';
import 'package:flutter_application_3_11/providers/repository_providers.dart';
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
        randomProvider.overrideWithValue(Random(7)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await hive.dispose();
  });

  MessyCanNotifier can() => container.read(messyCanProvider.notifier);
  List<Task> ideas() => container.read(messyCanProvider);
  List<String> titles(List<Task> list) => [for (final t in list) t.title];

  test('lists only Messy Can ideas, newest first', () async {
    await can().add('first');
    now = now.add(const Duration(minutes: 1));
    await can().add('second', note: '  a note ');
    await container.read(tasksProvider.notifier).add(title: 'board task');

    expect(titles(ideas()), ['second', 'first']);
    expect(ideas().first.description, 'a note');
    expect(ideas().every((t) => t.status == TaskStatus.messyCan), isTrue);
  });

  test('blank titles are ignored for add and edit', () async {
    expect(await can().add('   '), isNull);
    final idea = (await can().add('keep'))!;
    await can().edit(idea.id, title: '  ', note: 'x');
    expect(ideas().single.title, 'keep');

    await can().edit(idea.id, title: ' renamed ', note: ' note ');
    expect(ideas().single.title, 'renamed');
    expect(ideas().single.description, 'note');
  });

  test('delete returns the idea and undo restores it unchanged', () async {
    final idea = (await can().add('oops', note: 'n'))!;
    final deleted = await can().delete(idea.id);
    expect(ideas(), isEmpty);
    expect(deleted, idea);

    now = now.add(const Duration(hours: 1));
    await can().undoDelete(deleted!);
    expect(ideas().single, idea); // same updatedAt too
    expect(await can().delete('missing'), isNull);
  });

  test('promote moves the idea to the board with the chosen fields', () async {
    final idea = (await can().add('ship it'))!;
    now = now.add(const Duration(minutes: 5));
    await can().promote(
      idea.id,
      Promotion(
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        dueDate: DateTime(2026, 11, 9),
      ),
    );

    expect(ideas(), isEmpty);
    final task = container.read(tasksProvider.notifier).byId(idea.id)!;
    expect(task.status, TaskStatus.inProgress);
    expect(task.priority, TaskPriority.high);
    expect(task.dueDate, DateTime(2026, 11, 9));
    expect(task.updatedAt, now);
  });

  test('promote can clear a due date', () async {
    final idea = (await can().add('x'))!;
    await container
        .read(tasksProvider.notifier)
        .save(idea.copyWith(dueDate: DateTime(2026, 12, 1)));
    await can().promote(idea.id, const Promotion());
    expect(container.read(tasksProvider).single.dueDate, isNull);
  });

  group('randomizer', () {
    test('empty can gives nothing', () {
      expect(container.read(ideaPickerProvider).pick(), isNull);
    });

    test('one idea is drawn every time, even on "draw again"', () async {
      final only = (await can().add('only'))!;
      final picker = container.read(ideaPickerProvider);
      expect(picker.pick(), only);
      expect(picker.pick(excludeId: only.id), only);
    });

    test('never draws board tasks; draw again avoids the last one', () async {
      final a = (await can().add('a'))!;
      await can().add('b');
      await container.read(tasksProvider.notifier).add(title: 'board');

      final picker = container.read(ideaPickerProvider);
      for (var i = 0; i < 20; i++) {
        expect(picker.pick()!.isMessyCan, isTrue);
        expect(picker.pick(excludeId: a.id)!.title, 'b');
      }
    });
  });
}
