import 'package:flutter/material.dart';

import '../../data/models/task.dart';
import '../../providers/messy_can_provider.dart';
import '../widgets/choice_chip_group.dart';
import '../widgets/due_date_field.dart';
import '../widgets/priority_indicator.dart';

/// Bottom sheet to choose where a promoted idea lands: column, priority and
/// due date. Resolves to the [Promotion], or `null` when dismissed.
///
/// Stateful only to hold the choices being made in the open sheet (local,
/// visual state); nothing is saved until "Promote" is tapped.
class PromoteSheet extends StatefulWidget {
  const PromoteSheet({super.key, required this.idea, required this.now});

  final Task idea;
  final DateTime now;

  static Future<Promotion?> show(
    BuildContext context, {
    required Task idea,
    required DateTime now,
  }) => showModalBottomSheet<Promotion>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => PromoteSheet(idea: idea, now: now),
  );

  @override
  State<PromoteSheet> createState() => _PromoteSheetState();
}

class _PromoteSheetState extends State<PromoteSheet> {
  late Promotion _choice = Promotion(
    priority: widget.idea.priority,
    dueDate: widget.idea.dueDate,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Promote to board',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.idea.title,
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const _Label('Column'),
            ChoiceChipGroup<TaskStatus>(
              options: TaskStatus.boardColumns,
              selected: _choice.status,
              labelOf: (s) => s.label,
              onSelected: (s) =>
                  setState(() => _choice = _choice.copyWith(status: s)),
            ),
            const _Label('Priority'),
            ChoiceChipGroup<TaskPriority>(
              options: TaskPriority.values,
              selected: _choice.priority,
              labelOf: (p) => p.label,
              leadingOf: (p) => PriorityIndicator(priority: p),
              onSelected: (p) =>
                  setState(() => _choice = _choice.copyWith(priority: p)),
            ),
            const _Label('Due date'),
            DueDateField(
              dueDate: _choice.dueDate,
              now: widget.now,
              onChanged: (d) =>
                  setState(() => _choice = _choice.copyWith(dueDate: d)),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, _choice),
                icon: const Icon(Icons.rocket_launch_outlined),
                label: const Text('Promote'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(fontWeight: FontWeight.w600),
    ),
  );
}
