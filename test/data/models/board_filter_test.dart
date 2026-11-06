import 'package:flutter_application_3_11/data/models/board_filter.dart';
import 'package:flutter_application_3_11/data/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final base = DateTime(2026, 11, 1);

  Task task(
    String id, {
    TaskPriority priority = TaskPriority.medium,
    String category = 'Work',
    List<String> labels = const [],
    DateTime? dueDate,
    int createdDay = 1,
  }) => Task(
    id: id,
    title: id,
    priority: priority,
    category: category,
    labels: labels,
    dueDate: dueDate,
    createdAt: DateTime(2026, 11, createdDay),
    updatedAt: base,
  );

  List<String> ids(List<Task> tasks) => [for (final t in tasks) t.id];

  group('matches', () {
    final a = task(
      'a',
      priority: TaskPriority.high,
      category: 'Work',
      labels: ['urgent', 'home'],
    );
    final b = task('b', priority: TaskPriority.low, category: 'Chores');

    test('no filters matches everything', () {
      final f = BoardFilter();
      expect(f.hasFilters, isFalse);
      expect([a, b].where(f.matches), [a, b]);
    });

    test('any value within a group matches', () {
      final f = BoardFilter(categories: {'Work', 'Chores'});
      expect([a, b].where(f.matches), [a, b]);
      expect(BoardFilter(labels: {'home', 'x'}).matches(a), isTrue);
      expect(BoardFilter(labels: {'home'}).matches(b), isFalse);
    });

    test('all groups must match', () {
      final f = BoardFilter(
        priorities: {TaskPriority.high},
        categories: {'Chores'},
      );
      expect(f.hasFilters, isTrue);
      expect([a, b].where(f.matches), isEmpty);
    });
  });

  group('sort', () {
    test('default: newest created first', () {
      final tasks = [
        task('old', createdDay: 1),
        task('new', createdDay: 3),
        task('mid', createdDay: 2),
      ];
      expect(ids(BoardFilter().sort(tasks)), ['new', 'mid', 'old']);
      expect(ids(BoardFilter(ascending: true).sort(tasks)), [
        'old',
        'mid',
        'new',
      ]);
    });

    test('priority ascending = high first; ties newest first', () {
      final tasks = [
        task('low', priority: TaskPriority.low),
        task('high1', priority: TaskPriority.high, createdDay: 1),
        task('high2', priority: TaskPriority.high, createdDay: 2),
        task('med'),
      ];
      final f = BoardFilter(sortField: TaskSortField.priority, ascending: true);
      expect(ids(f.sort(tasks)), ['high2', 'high1', 'med', 'low']);
      expect(ids(f.copyWith(ascending: false).sort(tasks)), [
        'low',
        'med',
        'high2',
        'high1',
      ]);
    });

    test('due date: tasks without a due date go last both ways', () {
      final tasks = [
        task('none'),
        task('late', dueDate: DateTime(2026, 12, 1)),
        task('soon', dueDate: DateTime(2026, 11, 10)),
      ];
      final f = BoardFilter(sortField: TaskSortField.dueDate, ascending: true);
      expect(ids(f.sort(tasks)), ['soon', 'late', 'none']);
      expect(ids(f.copyWith(ascending: false).sort(tasks)), [
        'late',
        'soon',
        'none',
      ]);
    });

    test('apply filters then sorts, without changing the input', () {
      final tasks = [
        task('a', category: 'Work', createdDay: 1),
        task('b', category: 'Chores', createdDay: 2),
        task('c', category: 'Work', createdDay: 3),
      ];
      expect(ids(BoardFilter(categories: {'Work'}).apply(tasks)), ['c', 'a']);
      expect(ids(tasks), ['a', 'b', 'c']);
    });
  });

  test('clearFilters keeps the sort order; equality compares sets', () {
    final f = BoardFilter(
      labels: {'x'},
      sortField: TaskSortField.priority,
      ascending: true,
    );
    expect(
      f.clearFilters(),
      BoardFilter(sortField: TaskSortField.priority, ascending: true),
    );
    expect(BoardFilter(labels: {'a', 'b'}), BoardFilter(labels: {'b', 'a'}));
    expect(
      BoardFilter(labels: {'a', 'b'}).hashCode,
      BoardFilter(labels: {'b', 'a'}).hashCode,
    );
  });
}
