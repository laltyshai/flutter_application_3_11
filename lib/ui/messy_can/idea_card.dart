import 'package:flutter/material.dart';

import '../../data/models/task.dart';

enum _IdeaMenu { edit, openEditor, delete }

/// One idea in the can: title, optional note, Promote button and a menu.
class IdeaCard extends StatelessWidget {
  const IdeaCard({
    super.key,
    required this.idea,
    this.onTap,
    this.onPromote,
    this.onOpenEditor,
    this.onDelete,
  });

  final Task idea;

  /// Quick edit (title + note).
  final VoidCallback? onTap;
  final VoidCallback? onPromote;
  final VoidCallback? onOpenEditor;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = idea.description;
    final hasMenu = onTap != null || onOpenEditor != null || onDelete != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: const Icon(Icons.lightbulb_outline),
        ),
        title: Text(
          idea.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: note.isEmpty
            ? null
            : Text(note, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onPromote != null)
              IconButton(
                icon: const Icon(Icons.rocket_launch_outlined),
                tooltip: 'Promote to board',
                onPressed: onPromote,
              ),
            if (hasMenu)
              PopupMenuButton<_IdeaMenu>(
                tooltip: 'More',
                onSelected: (item) => switch (item) {
                  _IdeaMenu.edit => onTap?.call(),
                  _IdeaMenu.openEditor => onOpenEditor?.call(),
                  _IdeaMenu.delete => onDelete?.call(),
                },
                itemBuilder: (_) => [
                  if (onTap != null)
                    const PopupMenuItem(
                      value: _IdeaMenu.edit,
                      child: Text('Quick edit'),
                    ),
                  if (onOpenEditor != null)
                    const PopupMenuItem(
                      value: _IdeaMenu.openEditor,
                      child: Text('Open in editor'),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: _IdeaMenu.delete,
                      child: Text('Delete'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
