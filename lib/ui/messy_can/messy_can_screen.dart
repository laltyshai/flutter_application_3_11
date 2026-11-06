import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/task.dart';
import '../../providers/messy_can_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/task_editor_provider.dart';
import '../task/task_editor_screen.dart';
import '../widgets/empty_state.dart';
import '../widgets/random_pick_dialog.dart';
import 'idea_card.dart';
import 'idea_edit_dialog.dart';
import 'idea_entry_field.dart';
import 'promote_sheet.dart';

/// Idea dump: fast entry on top, list of ideas, swipe to delete (with Undo),
/// promote to the board, and a randomizer.
class MessyCanScreen extends ConsumerWidget {
  const MessyCanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideas = ref.watch(messyCanProvider);
    final notifier = ref.read(messyCanProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messy Can'),
        actions: [
          IconButton(
            tooltip: 'Draw a random idea',
            icon: const Icon(Icons.casino_outlined),
            onPressed: ideas.isEmpty ? null : () => _draw(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          IdeaEntryField(
            onAdd: (title, note) => notifier.add(title, note: note),
          ),
          Expanded(
            child: ideas.isEmpty
                ? const SingleChildScrollView(
                    child: EmptyState(
                      icon: Icons.lightbulb_outline,
                      title: 'The can is empty',
                      message:
                          'Dump quick ideas here and promote them to tasks '
                          'later.',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: ideas.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, i) {
                      final idea = ideas[i];
                      return Dismissible(
                        key: ValueKey(idea.id),
                        direction: DismissDirection.endToStart,
                        background: const _DeleteBackground(),
                        onDismissed: (_) => _delete(context, ref, idea),
                        child: IdeaCard(
                          idea: idea,
                          onTap: () => _quickEdit(context, ref, idea),
                          onPromote: () => _promote(context, ref, idea),
                          onOpenEditor: () => TaskEditorScreen.open(
                            context,
                            TaskEditorArgs.edit(idea.id),
                          ),
                          onDelete: () => _delete(context, ref, idea),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static Future<void> _quickEdit(
    BuildContext context,
    WidgetRef ref,
    Task idea,
  ) async {
    final edited = await showIdeaEditDialog(context, idea);
    if (edited == null) return;
    await ref
        .read(messyCanProvider.notifier)
        .edit(idea.id, title: edited.title, note: edited.note);
  }

  static Future<void> _promote(
    BuildContext context,
    WidgetRef ref,
    Task idea,
  ) async {
    final to = await PromoteSheet.show(
      context,
      idea: idea,
      now: ref.read(clockProvider)(),
    );
    if (to == null) return;
    await ref.read(messyCanProvider.notifier).promote(idea.id, to);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('"${idea.title}" moved to ${to.status.label}'),
          ),
        );
    }
  }

  static Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Task idea,
  ) async {
    final notifier = ref.read(messyCanProvider.notifier);
    // Grab the messenger now: the dismissed tile's context goes away.
    final messenger = ScaffoldMessenger.of(context);
    final deleted = await notifier.delete(idea.id);
    if (deleted == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted "${deleted.title}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => notifier.undoDelete(deleted),
          ),
        ),
      );
  }

  /// Draws random ideas until the user promotes/edits one or closes.
  Future<void> _draw(BuildContext context, WidgetRef ref) async {
    String? previousId;
    while (true) {
      if (!context.mounted) return;
      final idea = ref.read(ideaPickerProvider).pick(excludeId: previousId);
      if (idea == null) return;
      final action = await showRandomPickDialog<_DrawAction>(
        context,
        title: 'Fished out of the can!',
        child: IdeaCard(idea: idea),
        actions: const [
          PickAction(_DrawAction.again, 'Draw again'),
          PickAction(_DrawAction.edit, 'Edit'),
          PickAction(_DrawAction.promote, 'Promote', primary: true),
        ],
      );
      if (!context.mounted) return;
      switch (action) {
        case _DrawAction.again:
          previousId = idea.id;
        case _DrawAction.edit:
          await _quickEdit(context, ref, idea);
          return;
        case _DrawAction.promote:
          await _promote(context, ref, idea);
          return;
        case null:
          return;
      }
    }
  }
}

enum _DrawAction { again, edit, promote }

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.delete_outline, color: scheme.onError),
    );
  }
}
