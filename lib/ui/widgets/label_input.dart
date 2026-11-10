import 'package:flutter/material.dart';

import '../../core/theme/label_colors.dart';
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
                _ColoredLabelChip(
                  label: label,
                  onDeleted: () => onRemove(label),
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
                  // Colored edge previews the color the label will get.
                  side: BorderSide(color: LabelColors.of(s), width: 2),
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

/// Removable label chip in the label's own color (same as on cards).
class _ColoredLabelChip extends StatelessWidget {
  const _ColoredLabelChip({required this.label, required this.onDeleted});

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final color = LabelColors.of(label);
    final onColor = LabelColors.onColor(color);
    return InputChip(
      label: Text(label),
      labelStyle: TextStyle(color: onColor, fontWeight: FontWeight.w600),
      backgroundColor: color,
      side: BorderSide.none,
      deleteIconColor: onColor,
      onDeleted: onDeleted,
      deleteButtonTooltipMessage: 'Remove $label',
    );
  }
}
