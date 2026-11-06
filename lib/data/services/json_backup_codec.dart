import 'dart:convert';

import '../models/app_settings.dart';
import '../models/backup_data.dart';
import '../models/task.dart';
import '../repositories/settings_repository.dart';
import 'backup_codec.dart';

/// Full backup: app id, schema version, export time, settings and tasks.
class JsonBackupCodec implements BackupCodec {
  const JsonBackupCodec();

  @override
  String encode(BackupData data) => const JsonEncoder.withIndent('  ').convert({
    'app': BackupData.appId,
    'schemaVersion': data.schemaVersion,
    'exportedAt': data.exportedAt?.toIso8601String(),
    'settings': data.settings?.toJson(),
    'tasks': [for (final t in data.tasks) t.toJson()],
  });

  @override
  BackupData decode(String text) {
    final Object? root;
    try {
      root = jsonDecode(text);
    } on FormatException {
      throw const FormatException('Not valid JSON');
    }
    if (root is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object at the top level');
    }
    final app = root['app'];
    if (app != null && app != BackupData.appId) {
      throw FormatException('This backup is from another app ("$app")');
    }
    final version = root['schemaVersion'];
    if (version is! int) {
      throw const FormatException('Missing schemaVersion');
    }
    if (version > SettingsRepository.currentSchemaVersion) {
      throw FormatException(
        'This backup is from a newer app version (schema $version)',
      );
    }
    final rawTasks = root['tasks'];
    if (rawTasks is! List) {
      throw const FormatException('Missing "tasks" list');
    }

    final tasks = [
      for (var i = 0; i < rawTasks.length; i++)
        decodeTaskAt(i, () {
          final raw = rawTasks[i];
          if (raw is! Map) throw const FormatException('not an object');
          return Task.fromJson(Map<String, dynamic>.from(raw));
        }),
    ];

    final rawSettings = root['settings'];
    final exportedAt = root['exportedAt'];
    return BackupData(
      schemaVersion: version,
      exportedAt: exportedAt is String ? DateTime.tryParse(exportedAt) : null,
      settings: rawSettings is Map
          ? AppSettings.fromJson(Map<String, dynamic>.from(rawSettings))
          : null,
      tasks: validateTasks(tasks),
    );
  }
}
