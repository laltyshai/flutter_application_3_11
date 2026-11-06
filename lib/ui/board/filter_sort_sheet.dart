import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/board_filter.dart';
import '../../data/models/task.dart';
import '../../providers/board_provider.dart';
import '../widgets/choice_chip_group.dart';
import '../widgets/multi_choice_chip_group.dart';
import '../widgets/priority_indicator.dart';

/// Bottom sheet to choose sort order and filter by priority, category and
/// label. Changes apply to the board immediately.
class FilterSortSheet extends ConsumerWidget {
  const FilterSortSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const FilterSortSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(boardFilterProvider);
    final notifier = ref.read(boardFilterProvider.notifier);
    final options = ref.watch(boardFilterOptionsProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter & sort',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const _SectionTitle('Sort by'),
              ChoiceChipGroup<TaskSortField>(
                options: TaskSortField.values,
                selected: filter.sortField,
                labelOf: (f) => f.label,
                onSelected: notifier.setSort,
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Ascending'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Descending'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {filter.ascending},
                onSelectionChanged: (s) => notifier.setAscending(s.single),
              ),
              const _SectionTitle('Priority'),
              MultiChoiceChipGroup<TaskPriority>(
                options: TaskPriority.values,
                selected: filter.priorities,
                labelOf: (p) => p.label,
                leadingOf: (p) => PriorityIndicator(priority: p),
                onToggle: notifier.togglePriority,
              ),
              const _SectionTitle('Category'),
              MultiChoiceChipGroup<String>(
                options: options.categories,
                selected: filter.categories,
                labelOf: (c) => c,
                onToggle: notifier.toggleCategory,
              ),
              const _SectionTitle('Labels'),
              if (options.labels.isEmpty)
                Text(
                  'No labels yet. Add them in the task editor.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                MultiChoiceChipGroup<String>(
                  options: options.labels,
                  selected: filter.labels,
                  labelOf: (l) => l,
                  onToggle: notifier.toggleLabel,
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  TextButton(
                    onPressed: filter.hasFilters ? notifier.clearFilters : null,
                    child: const Text('Clear filters'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

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
