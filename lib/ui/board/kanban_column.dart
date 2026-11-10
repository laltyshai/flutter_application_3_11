import 'package:flutter/material.dart';

import '../../data/models/task.dart';
import 'board_parts.dart';

/// One board column: header with count, and draggable cards. Accepts cards
/// dropped from other columns.
class KanbanColumn extends StatelessWidget {
  const KanbanColumn({
    super.key,
    required this.status,
    required this.tasks,
    required this.now,
    required this.onOpen,
    required this.onMove,
    this.onHeaderTap,
    this.onDragUpdate,
    this.onDoneChanged,
  });

  final TaskStatus status;
  final List<Task> tasks;
  final DateTime now;
  final ValueChanged<Task> onOpen;

  /// Called when a card from another column is dropped here.
  final void Function(Task task, TaskStatus to) onMove;
  final VoidCallback? onHeaderTap;
  final ValueChanged<DragUpdateDetails>? onDragUpdate;

  /// Called when a card's done checkbox is ticked or cleared.
  final void Function(Task task, bool done)? onDoneChanged;

  @override
  Widget build(BuildContext context) {
    return StatusDropTarget(
      status: status,
      onMove: onMove,
      builder: (context, highlighted) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatusHeader(
            title: status.label,
            count: tasks.length,
            onTap: onHeaderTap,
          ),
          Expanded(
            child: tasks.isEmpty
                ? EmptyStatusHint(highlighted: highlighted)
                : LayoutBuilder(
                    builder: (context, constraints) => ListView.separated(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 96),
                      itemCount: tasks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => DraggableTaskCard(
                        key: ValueKey(tasks[i].id),
                        task: tasks[i],
                        now: now,
                        width: constraints.maxWidth - 16,
                        onOpen: onOpen,
                        onDragUpdate: onDragUpdate,
                        onDoneChanged: onDoneChanged,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
