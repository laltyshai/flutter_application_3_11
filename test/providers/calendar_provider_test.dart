import 'package:flutter_application_3_11/data/models/task.dart';
import 'package:flutter_application_3_11/providers/calendar_provider.dart';
import 'package:flutter_application_3_11/providers/repository_providers.dart';
import 'package:flutter_application_3_11/providers/tasks_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_hive.dart';

void main() {
  final created = DateTime(2026, 11, 1);

  Task task(
    String id, {
    DateTime? due,
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    DateTime? createdAt,
  }) => Task(
    id: id,
    title: id,
    status: status,
    priority: priority,
    dueDate: due,
    createdAt: createdAt ?? created,
    updatedAt: created,
  );

  List<String> ids(List<Task>? tasks) => [for (final t in tasks ?? []) t.id];

  group('groupByDueDay', () {
    test('day boundaries: 00:00 and 23:59 are the same day', () {
      final byDay = groupByDueDay([
        task('start', due: DateTime(2026, 11, 5)),
        task('end', due: DateTime(2026, 11, 5, 23, 59, 59)),
        task('next', due: DateTime(2026, 11, 6)),
        task('prev', due: DateTime(2026, 11, 4, 23, 59, 59)),
      ]);
      expect(
        ids(byDay[DateTime(2026, 11, 5)]),
        unorderedEquals(['start', 'end']),
      );
      expect(ids(byDay[DateTime(2026, 11, 6)]), ['next']);
      expect(ids(byDay[DateTime(2026, 11, 4)]), ['prev']);
    });

    test('UTC due dates are grouped by the local day', () {
      final utc = DateTime.utc(2026, 11, 5, 23, 30);
      final local = utc.toLocal();
      final byDay = groupByDueDay([task('utc', due: utc)]);
      expect(byDay.keys.single, DateTime(local.year, local.month, local.day));
    });

    test('skips tasks without a due date and Messy Can ideas', () {
      final byDay = groupByDueDay([
        task('none'),
        task('idea', due: DateTime(2026, 11, 5), status: TaskStatus.messyCan),
      ]);
      expect(byDay, isEmpty);
    });

    test('sorts unfinished first, then priority, then oldest', () {
      final day = DateTime(2026, 11, 5);
      final byDay = groupByDueDay([
        task(
          'done',
          due: day,
          status: TaskStatus.done,
          priority: TaskPriority.high,
        ),
        task('low', due: day, priority: TaskPriority.low),
        task(
          'high-new',
          due: day,
          priority: TaskPriority.high,
          createdAt: DateTime(2026, 11, 3),
        ),
        task(
          'high-old',
          due: day,
          priority: TaskPriority.high,
          createdAt: DateTime(2026, 11, 2),
        ),
      ]);
      expect(ids(byDay[day]), ['high-old', 'high-new', 'low', 'done']);
    });
  });

  group('CalendarNotifier', () {
    late TestHive hive;
    late ProviderContainer container;
    final now = DateTime(2026, 11, 5, 21, 15);

    setUp(() async {
      hive = await TestHive.open();
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

    CalendarNotifier calendar() => container.read(calendarProvider.notifier);
    CalendarState state() => container.read(calendarProvider);

    test('starts on today (midnight), month view', () {
      expect(state().selectedDay, DateTime(2026, 11, 5));
      expect(state().focusedDay, DateTime(2026, 11, 5));
      expect(state().span, CalendarSpan.month);
    });

    test('selectDay keeps only the date of a calendar (UTC) day', () {
      calendar().selectDay(DateTime.utc(2026, 11, 10));
      expect(state().selectedDay, DateTime(2026, 11, 10));
      expect(state().selectedDay.isUtc, isFalse);
      expect(state().focusedDay, DateTime(2026, 11, 10));

      calendar().showPage(DateTime.utc(2026, 12, 1));
      expect(state().focusedDay, DateTime(2026, 12, 1));
      expect(state().selectedDay, DateTime(2026, 11, 10));

      calendar().goToToday();
      expect(state().selectedDay, DateTime(2026, 11, 5));

      calendar().setSpan(CalendarSpan.week);
      expect(state().span, CalendarSpan.week);
    });

    test('quickAdd creates a To Do task due on the selected day', () async {
      calendar().selectDay(DateTime.utc(2026, 11, 10));
      await calendar().quickAdd('  Call mom ');
      await calendar().quickAdd('   ');

      final added = container.read(tasksProvider).single;
      expect(added.title, 'Call mom');
      expect(added.status, TaskStatus.todo);
      expect(added.dueDate, DateTime(2026, 11, 10));
      expect(ids(container.read(selectedDayTasksProvider)), [added.id]);

      calendar().goToToday();
      expect(container.read(selectedDayTasksProvider), isEmpty);
    });

    test('setDone checks a task off and back', () async {
      await calendar().quickAdd('Gym');
      final id = container.read(tasksProvider).single.id;
      final tasks = container.read(tasksProvider.notifier);

      await tasks.setDone(id, true);
      expect(tasks.byId(id)!.status, TaskStatus.done);
      await tasks.setDone(id, false);
      expect(tasks.byId(id)!.status, TaskStatus.todo);
    });
  });
}
