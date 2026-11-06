import 'package:flutter/material.dart';

/// Fast entry at the top of the Messy Can: a title and an optional note.
/// Enter on the title (or the + button) hands both to [onAdd] and clears.
///
/// Stateful only to own its text controllers and focus (local, visual state).
class IdeaEntryField extends StatefulWidget {
  const IdeaEntryField({super.key, required this.onAdd});

  final void Function(String title, String note) onAdd;

  @override
  State<IdeaEntryField> createState() => _IdeaEntryFieldState();
}

class _IdeaEntryFieldState extends State<IdeaEntryField> {
  final _title = TextEditingController();
  final _note = TextEditingController();
  final _titleFocus = FocusNode();

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_title.text.trim().isEmpty) return;
    widget.onAdd(_title.text, _note.text);
    _title.clear();
    _note.clear();
    // Keep typing ideas without tapping the field again.
    _titleFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 4, 12),
        child: Column(
          children: [
            TextField(
              controller: _title,
              focusNode: _titleFocus,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Dump an idea…',
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add idea',
                  onPressed: _submit,
                ),
              ),
            ),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Note (optional)',
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
