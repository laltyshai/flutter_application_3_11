import 'package:flutter/material.dart';

import '../widgets/add_item_field.dart';

/// Bottom bar: type a title and press Enter (or +) to add a task for the
/// selected day.
class QuickAddBar extends StatelessWidget {
  const QuickAddBar({super.key, required this.dayLabel, required this.onAdd});

  /// Shown in the hint, e.g. "Today" or "Nov 10".
  final String dayLabel;
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: 2,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: AddItemField(
            hintText: 'Add a task for $dayLabel',
            addTooltip: 'Add task',
            onAdd: onAdd,
          ),
        ),
      ),
    );
  }
}
