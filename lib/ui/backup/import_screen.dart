import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/backup_merge.dart';
import '../../providers/backup_provider.dart';
import '../widgets/confirm_dialog.dart';

/// Paste or pick a backup → check it → preview → Restore or Merge.
/// Stateful only to own the paste field's text controller.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const ImportScreen()));

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  ImportNotifier get _notifier => ref.read(importProvider.notifier);

  Future<void> _pick() async {
    final text = await _notifier.pickFile();
    // Show what was loaded, without the change clearing the preview.
    if (text != null && mounted) _text.text = text;
  }

  Future<void> _apply(ImportMode mode, ImportState state) async {
    if (mode == ImportMode.restore) {
      final ok = await showConfirmDialog(
        context,
        title: 'Replace all data?',
        message:
            'Restore deletes everything on this device and replaces it with '
            'the ${state.preview?.total ?? 0} tasks in the backup.',
        confirmLabel: 'Restore',
        destructive: true,
      );
      if (!ok) return;
    }
    await _notifier.apply(mode);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importProvider);
    ref.listen(importProvider.select((s) => s.applied), (_, mode) {
      if (mode == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mode == ImportMode.restore
                ? 'Backup restored'
                : 'Backup merged into your data',
          ),
        ),
      );
      Navigator.of(context).pop();
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Import backup')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            controller: _text,
            minLines: 6,
            maxLines: 12,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'Backup text',
              hintText: 'Paste JSON or CSV here',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _notifier.clear(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: state.busy ? null : _pick,
                icon: const Icon(Icons.folder_open_outlined),
                label: const Text('Pick file'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: state.busy ? null : () => _notifier.load(_text.text),
                child: const Text('Check'),
              ),
            ],
          ),
          if (state.busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (state.error case final error?) ...[
            const SizedBox(height: 16),
            _ErrorBox(message: error),
          ],
          if (state.preview case final preview?) ...[
            const SizedBox(height: 16),
            _PreviewCard(
              preview: preview,
              hasSettings: state.data?.settings != null,
              enabled: state.canApply,
              onMerge: () => _apply(ImportMode.merge, state),
              onRestore: () => _apply(ImportMode.restore, state),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: scheme.error),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: TextStyle(color: scheme.error)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.preview,
    required this.hasSettings,
    required this.enabled,
    required this.onMerge,
    required this.onRestore,
  });

  final ImportPreview preview;
  final bool hasSettings;
  final bool enabled;
  final VoidCallback onMerge;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              preview.summary,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${preview.newerCount} existing tasks are newer in the backup. '
              '${hasSettings ? 'Includes settings.' : 'No settings (CSV).'}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Merge adds new tasks and updates older ones. '
              'Restore replaces everything.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: enabled ? onRestore : null,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  child: Text(ImportMode.restore.label),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: enabled ? onMerge : null,
                  child: Text(ImportMode.merge.label),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
