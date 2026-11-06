import 'package:flutter/material.dart';

/// Text field + add button that hands the typed text to [onAdd] and clears
/// itself. Used for labels, subtasks and quick-add bars.
///
/// Stateful only to own its [TextEditingController] (local, visual state).
class AddItemField extends StatefulWidget {
  const AddItemField({
    super.key,
    required this.hintText,
    required this.onAdd,
    this.addTooltip = 'Add',
  });

  final String hintText;
  final String addTooltip;
  final ValueChanged<String> onAdd;

  @override
  State<AddItemField> createState() => _AddItemFieldState();
}

class _AddItemFieldState extends State<AddItemField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        hintText: widget.hintText,
        isDense: true,
        suffixIcon: IconButton(
          icon: const Icon(Icons.add),
          tooltip: widget.addTooltip,
          onPressed: _submit,
        ),
      ),
    );
  }
}
