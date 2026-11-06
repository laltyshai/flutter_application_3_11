import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/task.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/task_editor_provider.dart';
import '../widgets/choice_chip_group.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/due_date_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/label_input.dart';
import '../widgets/priority_indicator.dart';
import 'subtask_list_editor.dart';

/// Create or edit a task. All editing logic lives in [TaskEditorNotifier];
/// this screen only renders the draft and forwards user actions.
class TaskEditorScreen extends ConsumerWidget {
  const TaskEditorScreen({super.key, required this.args});

  final TaskEditorArgs args;

  static Future<void> open(BuildContext context, TaskEditorArgs args) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => TaskEditorScreen(args: args)),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = taskEditorProvider(args);
    final editor = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final settings = ref.watch(settingsProvider);
    final now = ref.watch(clockProvider)();
    final draft = editor.draft;

    if (editor.notFound) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit task')),
        body: const EmptyState(
          icon: Icons.search_off,
          title: 'Task not found',
          message: 'It may have been deleted.',
        ),
      );
    }

    Future<void> save() async {
      final saved = await notifier.save();
      if (saved && context.mounted) Navigator.pop(context);
    }

    Future<void> delete() async {
      final ok = await showConfirmDialog(
        context,
        title: 'Delete task?',
        message: '"${draft.title}" will be removed permanently.',
        confirmLabel: 'Delete',
        destructive: true,
      );
      if (!ok) return;
      await notifier.delete();
      if (context.mounted) Navigator.pop(context);
    }

    final categories = [
      ...settings.categories,
      if (!settings.categories.contains(draft.category)) draft.category,
    ];

    return PopScope(
      canPop: !editor.isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await showConfirmDialog(
          context,
          title: 'Discard changes?',
          message: 'Your edits to this task will be lost.',
          confirmLabel: 'Discard',
          destructive: true,
        );
        if (discard && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(editor.isNew ? 'New task' : 'Edit task'),
          actions: [
            if (!editor.isNew)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete task',
                onPressed: delete,
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: editor.canSave ? save : null,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              initialValue: draft.title,
              autofocus: editor.isNew,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: notifier.setTitle,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: draft.description,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: notifier.setDescription,
            ),
            _Section(
              title: 'Status',
              child: ChoiceChipGroup<TaskStatus>(
                options: TaskStatus.values,
                selected: draft.status,
                labelOf: (s) => s.label,
                onSelected: notifier.setStatus,
              ),
            ),
            _Section(
              title: 'Priority',
              child: ChoiceChipGroup<TaskPriority>(
                options: TaskPriority.values,
                selected: draft.priority,
                labelOf: (p) => p.label,
                leadingOf: (p) => PriorityIndicator(priority: p),
                onSelected: notifier.setPriority,
              ),
            ),
            _Section(
              title: 'Category',
              child: ChoiceChipGroup<String>(
                options: categories,
                selected: draft.category,
                labelOf: (c) => c,
                onSelected: notifier.setCategory,
              ),
            ),
            _Section(
              title: 'Labels',
              child: LabelInput(
                labels: draft.labels,
                suggestions: settings.labels,
                onAdd: notifier.addLabel,
                onRemove: notifier.removeLabel,
              ),
            ),
            _Section(
              title: 'Due date',
              child: DueDateField(
                dueDate: draft.dueDate,
                now: now,
                onChanged: notifier.setDueDate,
              ),
            ),
            _Section(
              title: draft.subtasks.isEmpty
                  ? 'Subtasks'
                  : 'Subtasks (${draft.subtaskRatio})',
              child: SubtaskListEditor(
                subtasks: draft.subtasks,
                onAdd: notifier.addSubtask,
                onToggle: notifier.toggleSubtask,
                onRemove: notifier.removeSubtask,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
