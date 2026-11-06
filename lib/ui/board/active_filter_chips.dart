import 'package:flutter/material.dart';

import '../../data/models/board_filter.dart';
import '../../data/models/task.dart';

/// Horizontal row of removable chips, one per active filter, plus "Clear".
class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({
    super.key,
    required this.filter,
    required this.onRemoveLabel,
    required this.onRemoveCategory,
    required this.onRemovePriority,
    required this.onClear,
  });

  final BoardFilter filter;
  final ValueChanged<String> onRemoveLabel;
  final ValueChanged<String> onRemoveCategory;
  final ValueChanged<TaskPriority> onRemovePriority;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      for (final p in TaskPriority.values)
        if (filter.priorities.contains(p))
          _chip('${p.label} priority', () => onRemovePriority(p)),
      for (final c in filter.categories) _chip(c, () => onRemoveCategory(c)),
      for (final l in filter.labels) _chip('#$l', () => onRemoveLabel(l)),
      ActionChip(
        avatar: const Icon(Icons.clear_all, size: 18),
        label: const Text('Clear'),
        onPressed: onClear,
      ),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  static Widget _chip(String label, VoidCallback onDeleted) => InputChip(
    label: Text(label),
    onDeleted: onDeleted,
    deleteButtonTooltipMessage: 'Remove $label filter',
  );
}
