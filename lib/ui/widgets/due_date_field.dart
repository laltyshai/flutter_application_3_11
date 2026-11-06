import 'package:flutter/material.dart';

import '../../core/utils/date_utils.dart';

/// Shows the due date (or "No due date"); tap to pick, ✕ to clear.
class DueDateField extends StatelessWidget {
  const DueDateField({
    super.key,
    required this.dueDate,
    required this.now,
    required this.onChanged,
  });

  final DateTime? dueDate;
  final DateTime now;
  final ValueChanged<DateTime?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final today = AppDates.dayOf(now);
    final initial = dueDate ?? today;
    final first = initial.isBefore(today) ? initial : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(first.year - 1),
      lastDate: DateTime(today.year + 10),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final date = dueDate;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_outlined),
      title: Text(
        date == null ? 'No due date' : AppDates.formatRelative(date, now),
      ),
      onTap: () => _pick(context),
      trailing: date == null
          ? null
          : IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear due date',
              onPressed: () => onChanged(null),
            ),
    );
  }
}
