import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/backup_data.dart';
import '../data/repositories/settings_repository.dart';
import '../data/services/backup_codec.dart';
import '../data/services/backup_io.dart';
import '../data/services/backup_merge.dart';
import 'repository_providers.dart';
import 'settings_provider.dart';
import 'tasks_provider.dart';

// Platform services; overridden with fakes in tests.
final backupFileStoreProvider = Provider<BackupFileStore>(
  (ref) => const DocumentsBackupFileStore(),
);
final backupSharerProvider = Provider<BackupSharer>(
  (ref) => const SystemBackupSharer(),
);
final backupFilePickerProvider = Provider<BackupFilePicker>(
  (ref) => const SystemBackupFilePicker(),
);

/// Counts shown on the backup screen: board tasks and Messy Can ideas.
final backupSummaryProvider = Provider<({int tasks, int ideas})>((ref) {
  final all = ref.watch(tasksProvider);
  final ideas = all.where((t) => t.isMessyCan).length;
  return (tasks: all.length - ideas, ideas: ideas);
});

/// Export: writes a backup file (and optionally shares it).
/// State is the path of the last saved file; loading while writing.
final exportProvider = NotifierProvider<ExportNotifier, AsyncValue<String?>>(
  ExportNotifier.new,
);

class ExportNotifier extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() => const AsyncData(null);

  /// Saves to the app documents folder; returns the file path.
  Future<String> save(BackupFormat format) async {
    state = const AsyncLoading();
    try {
      final now = ref.read(clockProvider)();
      final data = BackupData(
        schemaVersion: SettingsRepository.currentSchemaVersion,
        exportedAt: now,
        settings: ref.read(settingsProvider),
        tasks: ref.read(tasksProvider),
      );
      final path = await ref
          .read(backupFileStoreProvider)
          .save(format.fileName(now), format.codec.encode(data));
      state = AsyncData(path);
      return path;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Saves, then opens the share sheet for the file.
  Future<void> share(BackupFormat format) async {
    final path = await save(format);
    await ref
        .read(backupSharerProvider)
        .shareFile(
          path,
          mimeType: format.mimeType,
          subject: 'Task Tracker backup (${format.label})',
        );
  }
}

/// Import flow state: parsed backup + preview, or an error message.
@immutable
class ImportState {
  const ImportState({
    this.data,
    this.preview,
    this.error,
    this.busy = false,
    this.applied,
  });

  final BackupData? data;
  final ImportPreview? preview;

  /// User-readable reason the last load/apply failed.
  final String? error;
  final bool busy;

  /// Set once the import was written.
  final ImportMode? applied;

  bool get canApply => data != null && !busy && applied == null;
}

final importProvider =
    NotifierProvider.autoDispose<ImportNotifier, ImportState>(
      ImportNotifier.new,
    );

class ImportNotifier extends Notifier<ImportState> {
  @override
  ImportState build() => const ImportState();

  /// Forgets a loaded backup or error (e.g. when the pasted text changes).
  void clear() {
    if (state.data != null || state.error != null) {
      state = const ImportState();
    }
  }

  /// Parses and validates [text]; nothing is written yet.
  void load(String text) {
    if (text.trim().isEmpty) {
      state = const ImportState(error: 'Paste a backup or pick a file first.');
      return;
    }
    try {
      final data = BackupFormat.detect(text).codec.decode(text);
      state = ImportState(
        data: data,
        preview: ImportPreview.of(
          current: ref.read(tasksProvider),
          incoming: data.tasks,
        ),
      );
    } on FormatException catch (e) {
      state = ImportState(error: 'Could not read the backup: ${e.message}');
    }
  }

  /// Picks a file and loads it. Returns its text (or `null` if cancelled).
  Future<String?> pickFile() async {
    state = const ImportState(busy: true);
    try {
      final text = await ref.read(backupFilePickerProvider).pickText();
      if (!ref.mounted) return text;
      if (text == null) {
        state = const ImportState();
      } else {
        load(text);
      }
      return text;
    } catch (e) {
      if (ref.mounted) {
        state = ImportState(error: 'Could not open the file: $e');
      }
      return null;
    }
  }

  /// Writes the loaded backup. Restore replaces everything (and settings, if
  /// the backup has them); merge adds new and newer tasks.
  Future<void> apply(ImportMode mode) async {
    final data = state.data;
    if (data == null || !state.canApply) return;
    final preview = state.preview;
    state = ImportState(data: data, preview: preview, busy: true);

    final tasks = ref.read(tasksProvider.notifier);
    final settings = ref.read(settingsProvider.notifier);
    try {
      switch (mode) {
        case ImportMode.restore:
          await tasks.replaceAll(data.tasks);
          if (data.settings case final s?) await settings.replace(s);
        case ImportMode.merge:
          await tasks.upsertAll(
            tasksToMerge(
              current: ref.read(tasksProvider),
              incoming: data.tasks,
            ),
          );
          await settings.replace(
            mergeSettings(ref.read(settingsProvider), data.settings),
          );
      }
      if (ref.mounted) {
        state = ImportState(data: data, preview: preview, applied: mode);
      }
    } catch (e) {
      debugPrint('Import failed: $e');
      if (ref.mounted) {
        state = ImportState(
          data: data,
          preview: preview,
          error: 'Import failed: $e',
        );
      }
    }
  }
}
