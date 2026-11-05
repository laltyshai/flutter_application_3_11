import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_application_3_11/data/models/app_settings.dart';
import 'package:flutter_application_3_11/data/models/task.dart';
import 'package:flutter_application_3_11/data/repositories/settings_repository.dart';
import 'package:flutter_application_3_11/data/repositories/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_hive.dart';

void main() {
  late TestHive hive;
  final now = DateTime(2026, 11, 5);

  setUp(() async => hive = await TestHive.open());
  tearDown(() => hive.dispose());

  group('TaskRepository', () {
    late TaskRepository repo;
    setUp(() => repo = TaskRepository(hive.boxes.tasks));

    test('upsert, getById, getAll, delete', () async {
      final a = Task.create(title: 'A', now: now);
      final b = Task.create(title: 'B', now: now);

      await repo.upsert(a);
      await repo.upsert(b);
      expect(repo.getById(a.id), a);
      expect(repo.getAll(), unorderedEquals([a, b]));

      await repo.upsert(a.copyWith(title: 'A2'));
      expect(repo.getById(a.id)?.title, 'A2');
      expect(repo.getAll(), hasLength(2));

      await repo.delete(a.id);
      expect(repo.getById(a.id), isNull);
      expect(repo.getAll(), [b]);
    });

    test('replaceAll clears old tasks', () async {
      await repo.upsertAll([
        Task.create(title: 'old 1', now: now),
        Task.create(title: 'old 2', now: now),
      ]);
      final fresh = Task.create(title: 'fresh', now: now);

      await repo.replaceAll([fresh]);

      expect(repo.getAll(), [fresh]);
    });

    test('skips corrupt entries instead of failing', () async {
      final good = Task.create(title: 'good', now: now);
      await repo.upsert(good);
      await hive.boxes.tasks.put('broken', '{not json');
      await hive.boxes.tasks.put('no-title', '{"id":"no-title"}');

      expect(repo.getAll(), [good]);
    });

    test('data survives closing and reopening the box', () async {
      final task = Task.create(title: 'persist me', now: now);
      await repo.upsert(task);
      await hive.boxes.tasks.close();

      final reopened = await TestHive.reopenTasks();
      expect(TaskRepository(reopened).getById(task.id), task);
    });

    test('watch emits on changes', () async {
      final events = repo.watch().take(2).toList();
      await repo.upsert(Task.create(title: 'A', now: now));
      await repo.clear();
      expect(await events, hasLength(2));
    });
  });

  group('SettingsRepository', () {
    late SettingsRepository repo;
    setUp(() => repo = SettingsRepository(hive.boxes.settings));

    test('returns defaults on first run', () {
      expect(repo.load(), AppSettings());
    });

    test('save and load', () async {
      final settings = AppSettings(themeMode: ThemeMode.dark, labels: ['x']);
      await repo.save(settings);
      expect(repo.load(), settings);
    });

    test('ensureSchema writes the version once', () async {
      expect(repo.schemaVersion, isNull);
      await repo.ensureSchema();
      expect(repo.schemaVersion, SettingsRepository.currentSchemaVersion);
    });

    test('falls back to defaults if the stored settings are corrupt', () async {
      await hive.boxes.settings.put('appSettings', 'garbage');
      expect(repo.load(), AppSettings());
    });
  });
}
