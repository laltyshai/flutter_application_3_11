import 'package:flutter/material.dart';

/// Multi-select chips for any set of options (labels, categories, ...).
class MultiChoiceChipGroup<T> extends StatelessWidget {
  const MultiChoiceChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onToggle,
    this.leadingOf,
  });

  final List<T> options;
  final Set<T> selected;
  final String Function(T option) labelOf;
  final ValueChanged<T> onToggle;

  /// Optional icon/indicator shown before each label.
  final Widget Function(T option)? leadingOf;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          FilterChip(
            label: Text(labelOf(option)),
            avatar: leadingOf?.call(option),
            selected: selected.contains(option),
            onSelected: (_) => onToggle(option),
          ),
      ],
    );
  }
}
