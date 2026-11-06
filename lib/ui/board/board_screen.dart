import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/board_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/task_editor_provider.dart';
import '../task/task_editor_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_card.dart';

/// Interim board: a single list of board tasks. Phase 4 turns this into
/// To Do / In Progress / Done columns with drag-and-drop.
class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(boardTasksProvider);
    final now = ref.watch(clockProvider)();

    return Scaffold(
      appBar: AppBar(title: const Text('Board')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            TaskEditorScreen.open(context, const TaskEditorArgs.create()),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
      body: tasks.isEmpty
          ? const EmptyState(
              icon: Icons.view_kanban_outlined,
              title: 'No tasks yet',
              message: 'Tap "New task" to add your first one.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: tasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final task = tasks[i];
                return TaskCard(
                  key: ValueKey(task.id),
                  task: task,
                  now: now,
                  onTap: () => TaskEditorScreen.open(
                    context,
                    TaskEditorArgs.edit(task.id),
                  ),
                );
              },
            ),
    );
  }
}
