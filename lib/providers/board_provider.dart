import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/board_filter.dart';
import '../data/models/task.dart';
import 'random_provider.dart';
import 'settings_provider.dart';
import 'tasks_provider.dart';

/// Active board filters and sort order (session only, not persisted).
final boardFilterProvider = NotifierProvider<BoardFilterNotifier, BoardFilter>(
  BoardFilterNotifier.new,
);

class BoardFilterNotifier extends Notifier<BoardFilter> {
  @override
  BoardFilter build() => BoardFilter();

  void toggleLabel(String label) =>
      state = state.copyWith(labels: _toggle(state.labels, label));

  void toggleCategory(String category) =>
      state = state.copyWith(categories: _toggle(state.categories, category));

  void togglePriority(TaskPriority priority) =>
      state = state.copyWith(priorities: _toggle(state.priorities, priority));

  void setSort(TaskSortField field) => state = state.copyWith(sortField: field);

  void setAscending(bool ascending) =>
      state = state.copyWith(ascending: ascending);

  void clearFilters() => state = state.clearFilters();

  static Set<T> _toggle<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};
}

/// True when any task is on the board (ignoring filters).
final boardHasTasksProvider = Provider<bool>(
  (ref) => ref
      .watch(tasksProvider)
      .any((t) => TaskStatus.boardColumns.contains(t.status)),
);

/// Filtered and sorted tasks for each board column, in column order.
final boardColumnsProvider = Provider<Map<TaskStatus, List<Task>>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final filter = ref.watch(boardFilterProvider);
  return {
    for (final status in TaskStatus.boardColumns)
      status: filter.apply(tasks.where((t) => t.status == status)),
  };
});

/// Values offered in the filter sheet: saved settings plus anything already
/// used by board tasks, sorted case-insensitively.
final boardFilterOptionsProvider =
    Provider<({List<String> labels, List<String> categories})>((ref) {
      final settings = ref.watch(settingsProvider);
      final tasks = ref
          .watch(tasksProvider)
          .where((t) => TaskStatus.boardColumns.contains(t.status));
      return (
        labels: _sortedUnique([
          ...settings.labels,
          for (final t in tasks) ...t.labels,
        ]),
        categories: _sortedUnique([
          ...settings.categories,
          for (final t in tasks) t.category,
        ]),
      );
    });

List<String> _sortedUnique(Iterable<String> values) =>
    values.toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

/// Picks the "next task to tackle" from pending (To Do + In Progress) tasks
/// that match the active filters.
final nextTaskPickerProvider = Provider<RandomTaskPicker>((ref) {
  final columns = ref.watch(boardColumnsProvider);
  return RandomTaskPicker([
    for (final entry in columns.entries)
      if (entry.key != TaskStatus.done) ...entry.value,
  ], ref.watch(randomProvider));
});
