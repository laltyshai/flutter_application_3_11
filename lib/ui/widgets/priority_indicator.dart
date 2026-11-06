import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/task.dart';

/// Colored dot (optionally with the priority name) for a [TaskPriority].
class PriorityIndicator extends StatelessWidget {
  const PriorityIndicator({
    super.key,
    required this.priority,
    this.showLabel = false,
  });

  final TaskPriority priority;
  final bool showLabel;

  /// One entry per priority; a new priority only needs a new entry here.
  static const colors = {
    TaskPriority.high: AppColors.priorityHigh,
    TaskPriority.medium: AppColors.priorityMedium,
    TaskPriority.low: AppColors.priorityLow,
  };

  static Color colorOf(TaskPriority p) => colors[p]!;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: colorOf(priority),
        shape: BoxShape.circle,
      ),
    );
    return Semantics(
      label: '${priority.label} priority',
      excludeSemantics: true,
      child: showLabel
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                dot,
                const SizedBox(width: 6),
                Text(
                  priority.label,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            )
          : dot,
    );
  }
}
