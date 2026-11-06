import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/task.dart';
import 'tasks_provider.dart';

/// Tasks shown on the board (everything except Messy Can), newest first.
/// Phase 4 replaces this with per-column lists plus filters and sorting.
final boardTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider);
  return [
    for (final t in tasks)
      if (TaskStatus.boardColumns.contains(t.status)) t,
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});
