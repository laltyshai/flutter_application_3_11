import 'package:flutter/material.dart';

/// One button in [showRandomPickDialog]; [value] is returned when tapped.
class PickAction<A> {
  const PickAction(this.value, this.label, {this.primary = false});

  final A value;
  final String label;

  /// Drawn as a filled button.
  final bool primary;
}

/// "Random pick" dialog: shows [child] (e.g. a task card) and resolves to
/// the tapped action's value, or `null` when dismissed.
Future<A?> showRandomPickDialog<A>(
  BuildContext context, {
  required String title,
  required Widget child,
  required List<PickAction<A>> actions,
}) => showDialog<A>(
  context: context,
  builder: (context) => AlertDialog(
    icon: const Icon(Icons.casino_outlined),
    title: Text(title, textAlign: TextAlign.center),
    content: child,
    actionsAlignment: MainAxisAlignment.center,
    actionsOverflowAlignment: OverflowBarAlignment.center,
    actions: [
      for (final action in actions)
        action.primary
            ? FilledButton(
                onPressed: () => Navigator.pop(context, action.value),
                child: Text(action.label),
              )
            : TextButton(
                onPressed: () => Navigator.pop(context, action.value),
                child: Text(action.label),
              ),
    ],
  ),
);
