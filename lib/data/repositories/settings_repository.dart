import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../models/app_settings.dart';

/// Stores [AppSettings] and the data schema version in a Hive box.
class SettingsRepository {
  SettingsRepository(this._box);

  /// Bump when the stored task/settings format changes, and add a migration.
  static const currentSchemaVersion = 1;

  static const _settingsKey = 'appSettings';
  static const _schemaVersionKey = 'schemaVersion';

  final Box<String> _box;

  /// Saved settings, or defaults on first run / if the entry is corrupt.
  AppSettings load() {
    final raw = _box.get(_settingsKey);
    if (raw == null) return AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('SettingsRepository: using defaults, corrupt settings: $e');
      return AppSettings();
    }
  }

  Future<void> save(AppSettings settings) =>
      _box.put(_settingsKey, jsonEncode(settings));

  /// Version of the stored data; `null` before the first [ensureSchema].
  int? get schemaVersion => int.tryParse(_box.get(_schemaVersionKey) ?? '');

  /// Records the schema version on first run. Future migrations go here.
  Future<void> ensureSchema() async {
    if (schemaVersion == null) {
      await _box.put(_schemaVersionKey, '$currentSchemaVersion');
    }
  }
}
