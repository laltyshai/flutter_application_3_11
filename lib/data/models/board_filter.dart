import 'package:flutter/foundation.dart';

import 'task.dart';

/// Sort modes for board columns. A new mode only needs a new entry with its
/// own comparator (ascending order).
enum TaskSortField {
  dueDate('Due date', _byDueDate),
  priority('Priority', _byPriority),
  createdAt('Created', _byCreatedAt);

  const TaskSortField(this.label, this.compare);
  final String label;

  /// Ascending comparator.
  final Comparator<Task> compare;

  static int _byDueDate(Task a, Task b) {
    final da = a.dueDate, db = b.dueDate;
    if (da == null || db == null) return 0; // handled in [BoardFilter.sort]
    return da.compareTo(db);
  }

  // Priorities are declared high → low, so ascending = high first.
  static int _byPriority(Task a, Task b) =>
      a.priority.index.compareTo(b.priority.index);

  static int _byCreatedAt(Task a, Task b) => a.createdAt.compareTo(b.createdAt);
}

/// Board filters and sort order.
///
/// Within one group (labels, categories, priorities) any selected value
/// matches; across groups all must match. An empty group doesn't filter.
@immutable
class BoardFilter {
  BoardFilter({
    Set<String> labels = const {},
    Set<String> categories = const {},
    Set<TaskPriority> priorities = const {},
    this.sortField = TaskSortField.createdAt,
    this.ascending = false,
  }) : labels = Set.unmodifiable(labels),
       categories = Set.unmodifiable(categories),
       priorities = Set.unmodifiable(priorities);

  final Set<String> labels;
  final Set<String> categories;
  final Set<TaskPriority> priorities;
  final TaskSortField sortField;
  final bool ascending;

  bool get hasFilters =>
      labels.isNotEmpty || categories.isNotEmpty || priorities.isNotEmpty;

  bool matches(Task task) =>
      (labels.isEmpty || task.labels.any(labels.contains)) &&
      (categories.isEmpty || categories.contains(task.category)) &&
      (priorities.isEmpty || priorities.contains(task.priority));

  /// Sorted copy of [tasks]. Tasks without a due date always go last when
  /// sorting by due date; ties fall back to newest first, then id.
  List<Task> sort(Iterable<Task> tasks) {
    int compare(Task a, Task b) {
      if (sortField == TaskSortField.dueDate) {
        final missing =
            (a.dueDate == null ? 1 : 0) - (b.dueDate == null ? 1 : 0);
        if (missing != 0) return missing;
      }
      final primary = sortField.compare(a, b);
      if (primary != 0) return ascending ? primary : -primary;
      final newer = b.createdAt.compareTo(a.createdAt);
      return newer != 0 ? newer : a.id.compareTo(b.id);
    }

    return tasks.toList()..sort(compare);
  }

  /// Matching tasks, sorted.
  List<Task> apply(Iterable<Task> tasks) => sort(tasks.where(matches));

  BoardFilter copyWith({
    Set<String>? labels,
    Set<String>? categories,
    Set<TaskPriority>? priorities,
    TaskSortField? sortField,
    bool? ascending,
  }) => BoardFilter(
    labels: labels ?? this.labels,
    categories: categories ?? this.categories,
    priorities: priorities ?? this.priorities,
    sortField: sortField ?? this.sortField,
    ascending: ascending ?? this.ascending,
  );

  /// Same sort order, no filters.
  BoardFilter clearFilters() =>
      BoardFilter(sortField: sortField, ascending: ascending);

  @override
  bool operator ==(Object other) =>
      other is BoardFilter &&
      setEquals(other.labels, labels) &&
      setEquals(other.categories, categories) &&
      setEquals(other.priorities, priorities) &&
      other.sortField == sortField &&
      other.ascending == ascending;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(labels),
    Object.hashAllUnordered(categories),
    Object.hashAllUnordered(priorities),
    sortField,
    ascending,
  );
}
