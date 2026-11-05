import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_settings.dart';
import '../data/repositories/settings_repository.dart';
import 'repository_providers.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  @override
  AppSettings build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> replace(AppSettings settings) async {
    await _repo.save(settings);
    state = settings;
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      replace(state.copyWith(themeMode: mode));

  /// Adds a category if it's new (case-insensitive) and non-blank.
  Future<void> addCategory(String name) async {
    final updated = _addUnique(state.categories, name);
    if (updated != null) await replace(state.copyWith(categories: updated));
  }

  /// Adds a label if it's new (case-insensitive) and non-blank.
  Future<void> addLabel(String name) async {
    final updated = _addUnique(state.labels, name);
    if (updated != null) await replace(state.copyWith(labels: updated));
  }

  static List<String>? _addUnique(List<String> list, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final lower = trimmed.toLowerCase();
    if (list.any((e) => e.toLowerCase() == lower)) return null;
    return [...list, trimmed];
  }
}
