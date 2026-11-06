import 'package:flutter/material.dart';

import '../../data/models/task.dart';
import '../widgets/task_card.dart';

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
  });

  final TaskStatus status;
  final List<Task> tasks;
  final DateTime now;
  final ValueChanged<Task> onOpen;

  /// Called when a card from another column is dropped here.
  final void Function(Task task, TaskStatus to) onMove;
  final VoidCallback? onHeaderTap;
  final ValueChanged<DragUpdateDetails>? onDragUpdate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DragTarget<Task>(
      onWillAcceptWithDetails: (d) => d.data.status != status,
      onAcceptWithDetails: (d) => onMove(d.data, status),
      builder: (context, candidates, _) {
        final highlighted = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: highlighted
                ? scheme.primaryContainer.withValues(alpha: 0.5)
                : scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlighted ? scheme.primary : scheme.outlineVariant,
              width: highlighted ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ColumnHeader(
                title: status.label,
                count: tasks.length,
                onTap: onHeaderTap,
              ),
              Expanded(
                child: tasks.isEmpty
                    ? _EmptyColumn(highlighted: highlighted)
                    : _CardList(
                        tasks: tasks,
                        now: now,
                        onOpen: onOpen,
                        onDragUpdate: onDragUpdate,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({required this.title, required this.count, this.onTap});

  final String title;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Semantics(
          header: true,
          label: '$title, $count tasks',
          excludeSemantics: true,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardList extends StatelessWidget {
  const _CardList({
    required this.tasks,
    required this.now,
    required this.onOpen,
    this.onDragUpdate,
  });

  final List<Task> tasks;
  final DateTime now;
  final ValueChanged<Task> onOpen;
  final ValueChanged<DragUpdateDetails>? onDragUpdate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Dragged card keeps the column's card width.
        final cardWidth = constraints.maxWidth - 16;
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 96),
          itemCount: tasks.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final task = tasks[i];
            final card = TaskCard(
              task: task,
              now: now,
              onTap: () => onOpen(task),
            );
            return LongPressDraggable<Task>(
              key: ValueKey(task.id),
              data: task,
              onDragUpdate: onDragUpdate,
              feedback: SizedBox(
                width: cardWidth,
                child: Material(
                  type: MaterialType.transparency,
                  child: Transform.rotate(angle: 0.03, child: card),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.35, child: card),
              child: card,
            );
          },
        );
      },
    );
  }
}

class _EmptyColumn extends StatelessWidget {
  const _EmptyColumn({required this.highlighted});

  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Align(
        alignment: Alignment.topCenter,
        child: Text(
          highlighted ? 'Drop here' : 'No tasks',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
