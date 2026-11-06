import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/backup_codec.dart';
import '../../providers/backup_provider.dart';
import 'import_screen.dart';

/// Export (save or share as JSON/CSV) and the entry point to import.
/// Stateful only for the selected export format (local, visual state).
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  BackupFormat _format = BackupFormat.json;

  Future<void> _run(Future<String?> Function() action) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final message = await action();
      if (message != null) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = ref.watch(backupSummaryProvider);
    final busy = ref.watch(exportProvider).isLoading;
    final export = ref.read(exportProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Backup')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Backup & restore',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your data stays on this device. Export a copy to keep it safe '
            'or move it to another phone.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _Section(
            icon: Icons.upload_file_outlined,
            title: 'Export',
            children: [
              Text(
                'Tasks: ${summary.tasks} · Ideas: ${summary.ideas}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<BackupFormat>(
                segments: [
                  for (final f in BackupFormat.values)
                    ButtonSegment(value: f, label: Text(f.label)),
                ],
                selected: {_format},
                onSelectionChanged: (s) => setState(() => _format = s.single),
              ),
              const SizedBox(height: 8),
              Text(_format.description, style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => _run(() async {
                            final path = await export.save(_format);
                            return 'Saved to $path';
                          }),
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Save to device'),
                  ),
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => _run(() async {
                            await export.share(_format);
                            return null;
                          }),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            icon: Icons.download_outlined,
            title: 'Import',
            children: [
              Text(
                'Paste a backup or pick a .json/.csv file, check what it '
                'contains, then restore or merge.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => ImportScreen.open(context),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Import backup'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
