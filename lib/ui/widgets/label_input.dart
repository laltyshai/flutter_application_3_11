import 'package:flutter/material.dart';

import 'add_item_field.dart';

/// Current labels as removable chips, known labels as quick-add suggestions,
/// and a field to type a new one.
class LabelInput extends StatelessWidget {
  const LabelInput({
    super.key,
    required this.labels,
    required this.suggestions,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> labels;

  /// Known labels; ones already in [labels] are hidden.
  final List<String> suggestions;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final used = {for (final l in labels) l.toLowerCase()};
    final unused = [
      for (final s in suggestions)
        if (!used.contains(s.toLowerCase())) s,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labels.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in labels)
                InputChip(
                  label: Text(label),
                  onDeleted: () => onRemove(label),
                  deleteButtonTooltipMessage: 'Remove $label',
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        AddItemField(
          hintText: 'Add a label',
          addTooltip: 'Add label',
          onAdd: onAdd,
        ),
        if (unused.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in unused)
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: Text(s),
                  onPressed: () => onAdd(s),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
