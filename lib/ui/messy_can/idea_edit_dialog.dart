import 'package:flutter/material.dart';

import '../../data/models/task.dart';

/// Quick edit of an idea's title and note. Resolves to the new values, or
/// `null` when cancelled.
Future<({String title, String note})?> showIdeaEditDialog(
  BuildContext context,
  Task idea,
) => showDialog(
  context: context,
  builder: (_) => _IdeaEditDialog(idea: idea),
);

/// Stateful only to own its text controllers (local, visual state).
class _IdeaEditDialog extends StatefulWidget {
  const _IdeaEditDialog({required this.idea});

  final Task idea;

  @override
  State<_IdeaEditDialog> createState() => _IdeaEditDialogState();
}

class _IdeaEditDialogState extends State<_IdeaEditDialog> {
  late final _title = TextEditingController(text: widget.idea.title);
  late final _note = TextEditingController(text: widget.idea.description);

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit idea'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Idea'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ListenableBuilder(
          listenable: _title,
          builder: (context, _) => FilledButton(
            onPressed: _title.text.trim().isEmpty
                ? null
                : () => Navigator.pop(context, (
                    title: _title.text,
                    note: _note.text,
                  )),
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}
