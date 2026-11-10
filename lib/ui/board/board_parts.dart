import 'package:flutter/material.dart';

import '../../data/models/task.dart';
import '../widgets/task_card.dart';

/// Building blocks shared by both board layouts (columns and rows).

/// Rounded panel for one status that accepts cards dropped from other
/// statuses and highlights while a card hovers over it.
class StatusDropTarget extends StatelessWidget {
  const StatusDropTarget({
    super.key,
    required this.status,
    required this.onMove,
    required this.builder,
  });

  final TaskStatus status;
  final void Function(Task task, TaskStatus to) onMove;

  /// Builds the panel content; `highlighted` is true while a card hovers.
  final Widget Function(BuildContext context, bool highlighted) builder;

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
          child: builder(context, highlighted),
        );
      },
    );
  }
}

/// Status title with a count badge.
class StatusHeader extends StatelessWidget {
  const StatusHeader({
    super.key,
    required this.title,
    required this.count,
    this.onTap,
  });

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

/// A [TaskCard] that can be long-pressed and dragged to another status.
class DraggableTaskCard extends StatelessWidget {
  const DraggableTaskCard({
    super.key,
    required this.task,
    required this.now,
    required this.width,
    required this.onOpen,
    this.onDragUpdate,
    this.onDoneChanged,
  });

  final Task task;
  final DateTime now;

  /// Width of the card while dragged (matches its place on the board).
  final double width;
  final ValueChanged<Task> onOpen;
  final ValueChanged<DragUpdateDetails>? onDragUpdate;

  /// Called when a card's done checkbox is ticked or cleared.
  final void Function(Task task, bool done)? onDoneChanged;

  @override
  Widget build(BuildContext context) {
    final onDone = onDoneChanged;
    final card = TaskCard(
      task: task,
      now: now,
      onTap: () => onOpen(task),
      onDoneChanged: onDone == null ? null : (done) => onDone(task, done),
    );
    return LongPressDraggable<Task>(
      data: task,
      onDragUpdate: onDragUpdate,
      feedback: SizedBox(
        width: width,
        child: Material(
          type: MaterialType.transparency,
          child: Transform.rotate(angle: 0.03, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }
}

/// "No tasks" / "Drop here" placeholder for an empty status.
class EmptyStatusHint extends StatelessWidget {
  const EmptyStatusHint({super.key, required this.highlighted});

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
