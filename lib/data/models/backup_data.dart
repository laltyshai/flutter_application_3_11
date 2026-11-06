import 'package:flutter/foundation.dart';

import 'app_settings.dart';
import 'task.dart';

/// Everything a backup file holds. [settings] is `null` for formats that
/// can't carry them (CSV); importing then leaves the current settings alone.
@immutable
class BackupData {
  BackupData({
    required this.schemaVersion,
    required this.exportedAt,
    required List<Task> tasks,
    this.settings,
  }) : tasks = List.unmodifiable(tasks);

  /// Written into JSON backups so imports can tell the file is ours.
  static const appId = 'flutter_application_3_11';

  final int schemaVersion;

  /// `null` when the source didn't say (e.g. CSV).
  final DateTime? exportedAt;
  final AppSettings? settings;
  final List<Task> tasks;
}
