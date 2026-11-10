import 'package:flutter/material.dart';

import '../../core/utils/date_utils.dart';
import '../../data/models/task.dart';
import 'category_badge.dart';
import 'label_chip.dart';
import 'priority_indicator.dart';

/// Compact task summary: priority, title, labels, category, subtask ratio,
/// due date,
/// and (when [onDoneChanged] is given) a "done" checkbox on the right.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.now,
    this.onTap,
    this.onLongPress,
    this.onDoneChanged,
  });

  final Task task;

  /// Used to show "Today"/"Overdue"; pass the app clock's time.
  final DateTime now;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Called with `true` when the checkbox is ticked, `false` when cleared.
  /// No checkbox is shown when this is null (e.g. in the random-pick dialog).
  final ValueChanged<bool>? onDoneChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final due = task.dueDate;
    final overdue = task.isOverdueAt(now);
    final isDone = task.status == TaskStatus.done;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            12,
            onDoneChanged == null ? 12 : 0,
            12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PriorityIndicator(priority: task.priority),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (task.labels.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final label in task.labels)
                            LabelChip(label: label),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        CategoryBadge(category: task.category),
                        if (task.subtasks.isNotEmpty)
                          _Meta(
                            icon: Icons.checklist,
                            text: task.subtaskRatio,
                            semanticLabel:
                                '${task.completedSubtasks} of '
                                '${task.subtasks.length} subtasks done',
                          ),
                        if (due != null)
                          _Meta(
                            icon: Icons.event_outlined,
                            text: overdue
                                ? 'Overdue · ${AppDates.formatRelative(due, now)}'
                                : AppDates.formatRelative(due, now),
                            color: overdue ? theme.colorScheme.error : null,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDoneChanged case final onDone?)
                Checkbox(
                  value: isDone,
                  semanticLabel: isDone
                      ? 'Mark "${task.title}" as not done'
                      : 'Mark "${task.title}" as done',
                  onChanged: (v) => onDone(v ?? false),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.text,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final String text;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: color,
      fontWeight: color != null ? FontWeight.w600 : null,
    );
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? style?.color),
          const SizedBox(width: 4),
          Text(text, style: style),
        ],
      ),
    );
  }
}
