import 'package:flutter/material.dart';

/// Single-choice chips for any set of options (statuses, priorities, ...).
class ChoiceChipGroup<T> extends StatelessWidget {
  const ChoiceChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.leadingOf,
  });

  final List<T> options;
  final T selected;
  final String Function(T option) labelOf;
  final ValueChanged<T> onSelected;

  /// Optional icon/indicator shown before each label.
  final Widget Function(T option)? leadingOf;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(labelOf(option)),
            avatar: leadingOf?.call(option),
            selected: option == selected,
            showCheckmark: false,
            onSelected: (_) => onSelected(option),
          ),
      ],
    );
  }
}
