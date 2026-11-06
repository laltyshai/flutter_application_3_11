import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_settings.dart';
import '../../data/models/task.dart';
import '../../providers/board_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_editor_provider.dart';
import '../../providers/tasks_provider.dart';
import '../task/task_editor_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/random_pick_dialog.dart';
import '../widgets/task_card.dart';
import 'active_filter_chips.dart';
import 'filter_sort_sheet.dart';
import 'kanban_board.dart';
import 'kanban_rows.dart';

/// Kanban board: To Do · In Progress · Done as rows or columns (see
/// Settings) with drag-and-drop,
/// filter/sort, and the random "next task" picker.
class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasTasks = ref.watch(boardHasTasksProvider);
    final columns = ref.watch(boardColumnsProvider);
    final filter = ref.watch(boardFilterProvider);
    final filterNotifier = ref.read(boardFilterProvider.notifier);
    final now = ref.watch(clockProvider)();
    final layout = ref.watch(settingsProvider.select((s) => s.boardLayout));
    void onOpen(Task task) => _open(context, task);
    void onMove(Task task, TaskStatus to) =>
        ref.read(tasksProvider.notifier).moveTo(task.id, to);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Board'),
        actions: [
          IconButton(
            tooltip: 'Pick a random task',
            icon: const Icon(Icons.casino_outlined),
            onPressed: hasTasks ? () => _pickRandom(context, ref) : null,
          ),
          IconButton(
            tooltip: 'Filter & sort',
            icon: Badge(
              isLabelVisible: filter.hasFilters,
              smallSize: 8,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () => FilterSortSheet.show(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            TaskEditorScreen.open(context, const TaskEditorArgs.create()),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
      body: !hasTasks
          ? const EmptyState(
              icon: Icons.view_kanban_outlined,
              title: 'No tasks yet',
              message: 'Tap "New task" to add your first one.',
            )
          : Column(
              children: [
                if (filter.hasFilters)
                  ActiveFilterChips(
                    filter: filter,
                    onRemoveLabel: filterNotifier.toggleLabel,
                    onRemoveCategory: filterNotifier.toggleCategory,
                    onRemovePriority: filterNotifier.togglePriority,
                    onClear: filterNotifier.clearFilters,
                  ),
                Expanded(
                  // Chosen in Settings → Board layout.
                  child: switch (layout) {
                    BoardLayout.rows => KanbanRows(
                      columns: columns,
                      now: now,
                      onOpen: onOpen,
                      onMove: onMove,
                    ),
                    BoardLayout.columns => KanbanBoard(
                      columns: columns,
                      now: now,
                      onOpen: onOpen,
                      onMove: onMove,
                    ),
                  },
                ),
              ],
            ),
    );
  }

  static void _open(BuildContext context, Task task) =>
      TaskEditorScreen.open(context, TaskEditorArgs.edit(task.id));

  /// Shows random picks until the user opens/starts one or closes the dialog.
  Future<void> _pickRandom(BuildContext context, WidgetRef ref) async {
    String? previousId;
    while (true) {
      if (!context.mounted) return;
      final task = ref.read(nextTaskPickerProvider).pick(excludeId: previousId);
      if (task == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No To Do or In Progress tasks to pick from.'),
          ),
        );
        return;
      }
      final action = await showRandomPickDialog<_NextTaskAction>(
        context,
        title: 'Your Next Task to Tackle!',
        child: TaskCard(task: task, now: ref.read(clockProvider)()),
        actions: [
          const PickAction(_NextTaskAction.again, 'Pick again'),
          const PickAction(_NextTaskAction.open, 'Open'),
          if (task.status != TaskStatus.inProgress)
            const PickAction(_NextTaskAction.start, 'Start', primary: true),
        ],
      );
      if (!context.mounted) return;
      switch (action) {
        case _NextTaskAction.again:
          previousId = task.id;
        case _NextTaskAction.open:
          _open(context, task);
          return;
        case _NextTaskAction.start:
          await ref
              .read(tasksProvider.notifier)
              .moveTo(task.id, TaskStatus.inProgress);
          return;
        case null:
          return;
      }
    }
  }
}

enum _NextTaskAction { again, open, start }
