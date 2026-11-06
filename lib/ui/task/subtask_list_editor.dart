import 'package:flutter/material.dart';

import '../../data/models/subtask.dart';
import '../widgets/add_item_field.dart';

/// Checklist of subtasks with check / remove, plus a field to add one.
class SubtaskListEditor extends StatelessWidget {
  const SubtaskListEditor({
    super.key,
    required this.subtasks,
    required this.onAdd,
    required this.onToggle,
    required this.onRemove,
  });

  final List<Subtask> subtasks;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onToggle;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final s in subtasks)
          CheckboxListTile(
            key: ValueKey(s.id),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: s.isDone,
            onChanged: (_) => onToggle(s.id),
            title: Text(
              s.title,
              style: s.isDone
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
                  : null,
            ),
            secondary: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove subtask',
              onPressed: () => onRemove(s.id),
            ),
          ),
        const SizedBox(height: 4),
        AddItemField(
          hintText: 'Add a subtask',
          addTooltip: 'Add subtask',
          onAdd: onAdd,
        ),
      ],
    );
  }
}
