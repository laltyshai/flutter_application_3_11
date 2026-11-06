import 'package:flutter/material.dart';

import '../../data/models/task.dart';
import '../widgets/empty_state.dart';
import '../widgets/task_card.dart';

/// Tasks due on the selected day, each with a "done" checkbox.
/// Not scrollable itself: the screen scrolls it together with the calendar.
class AgendaList extends StatelessWidget {
  const AgendaList({
    super.key,
    required this.title,
    required this.tasks,
    required this.now,
    required this.onOpen,
    required this.onDoneChanged,
  });

  /// Day heading, e.g. "Thursday, Nov 5".
  final String title;
  final List<Task> tasks;
  final DateTime now;
  final ValueChanged<Task> onOpen;
  final void Function(Task task, bool done) onDoneChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              tasks.isEmpty ? title : '$title · ${tasks.length}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (tasks.isEmpty)
            const EmptyState(
              icon: Icons.event_available_outlined,
              title: 'Nothing scheduled',
              message: 'Type below to add a task for this day.',
            )
          else
            for (final task in tasks)
              Padding(
                key: ValueKey(task.id),
                padding: const EdgeInsets.only(bottom: 8),
                child: _AgendaTile(
                  task: task,
                  now: now,
                  onOpen: () => onOpen(task),
                  onDoneChanged: (done) => onDoneChanged(task, done),
                ),
              ),
        ],
      ),
    );
  }
}

class _AgendaTile extends StatelessWidget {
  const _AgendaTile({
    required this.task,
    required this.now,
    required this.onOpen,
    required this.onDoneChanged,
  });

  final Task task;
  final DateTime now;
  final VoidCallback onOpen;
  final ValueChanged<bool> onDoneChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: task.status == TaskStatus.done,
          semanticLabel: 'Done: ${task.title}',
          onChanged: (v) => onDoneChanged(v ?? false),
        ),
        Expanded(
          child: TaskCard(task: task, now: now, onTap: onOpen),
        ),
      ],
    );
  }
}
