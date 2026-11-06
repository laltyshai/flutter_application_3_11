import 'dart:convert';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_application_3_11/data/models/app_settings.dart';
import 'package:flutter_application_3_11/data/models/backup_data.dart';
import 'package:flutter_application_3_11/data/models/subtask.dart';
import 'package:flutter_application_3_11/data/models/task.dart';
import 'package:flutter_application_3_11/data/services/backup_codec.dart';
import 'package:flutter_application_3_11/data/services/csv_backup_codec.dart';
import 'package:flutter_application_3_11/data/services/json_backup_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final created = DateTime(2026, 11, 1, 8, 30);

  final tricky = Task(
    id: 'a1',
    title: 'Buy "good", cheap paint',
    description: 'Line one\nline two, with comma',
    status: TaskStatus.inProgress,
    priority: TaskPriority.high,
    category: 'Chores',
    labels: const ['home', 'diy'],
    dueDate: DateTime(2026, 11, 9),
    subtasks: const [
      Subtask(id: 's1', title: 'White, matte', isDone: true),
      Subtask(id: 's2', title: 'Brush'),
    ],
    createdAt: created,
    updatedAt: created.add(const Duration(hours: 2)),
  );
  final plain = Task(
    id: 'b2',
    title: 'Idea',
    status: TaskStatus.messyCan,
    createdAt: created,
    updatedAt: created,
  );

  BackupData backup({AppSettings? settings}) => BackupData(
    schemaVersion: 1,
    exportedAt: DateTime(2026, 11, 5, 9),
    settings: settings,
    tasks: [tricky, plain],
  );

  void expectFormatError(BackupCodec codec, String text, Object message) =>
      expect(
        () => codec.decode(text),
        throwsA(
          isA<FormatException>().having((e) => e.message, 'message', message),
        ),
      );

  group('JSON', () {
    const codec = JsonBackupCodec();

    test('round-trips tasks and settings', () {
      final settings = AppSettings(
        themeMode: ThemeMode.dark,
        categories: const ['Work', 'Garden'],
        labels: const ['home'],
      );
      final text = codec.encode(backup(settings: settings));
      final json = jsonDecode(text) as Map<String, dynamic>;
      expect(json['app'], BackupData.appId);
      expect(json['schemaVersion'], 1);

      final back = codec.decode(text);
      expect(back.tasks, [tricky, plain]);
      expect(back.settings, settings);
      expect(back.exportedAt, DateTime(2026, 11, 5, 9));
    });

    test('rejects malformed input with clear messages', () {
      expectFormatError(codec, '{oops', 'Not valid JSON');
      expectFormatError(codec, '[]', contains('JSON object'));
      expectFormatError(
        codec,
        '{"app":"other","schemaVersion":1,"tasks":[]}',
        contains('another app'),
      );
      expectFormatError(codec, '{"tasks":[]}', 'Missing schemaVersion');
      expectFormatError(
        codec,
        '{"schemaVersion":99,"tasks":[]}',
        contains('newer app version'),
      );
      expectFormatError(codec, '{"schemaVersion":1}', contains('"tasks"'));
    });

    test('a bad task fails the whole import and says which one', () {
      final good = jsonEncode(plain.toJson());
      expectFormatError(
        codec,
        '{"schemaVersion":1,"tasks":[$good, {"id":"x"}]}',
        startsWith('Task 2:'),
      );
      expectFormatError(
        codec,
        '{"schemaVersion":1,"tasks":[$good, 5]}',
        'Task 2: not an object',
      );
      expectFormatError(
        codec,
        '{"schemaVersion":1,"tasks":[$good, $good]}',
        contains('Duplicate task id "b2"'),
      );
    });
  });

  group('CSV', () {
    const codec = CsvBackupCodec();

    test('round-trips quotes, commas, newlines, labels and subtasks', () {
      final text = codec.encode(backup(settings: AppSettings()));
      expect(text.split('\n').first, CsvBackupCodec.columns.join(','));

      final back = codec.decode(text);
      expect(back.tasks, [tricky, plain]);
      expect(back.settings, isNull); // CSV carries tasks only
    });

    test('accepts a UTF-8 BOM and missing optional columns', () {
      final back = codec.decode(
        '﻿id,title,createdAt\nx1,Hello,2026-11-01T08:00:00.000\n',
      );
      final t = back.tasks.single;
      expect(t.title, 'Hello');
      expect(t.status, TaskStatus.todo);
      expect(t.labels, isEmpty);
      expect(t.dueDate, isNull);
      expect(t.updatedAt, t.createdAt);
    });

    test('rejects malformed input', () {
      expectFormatError(codec, '', 'The CSV is empty');
      expectFormatError(codec, 'id,title\nx,y', contains('"createdAt"'));
      expectFormatError(
        codec,
        'id,title,createdAt\nx,y,not-a-date',
        startsWith('Task 1:'),
      );
      expectFormatError(
        codec,
        'id,title,createdAt,subtasks\nx,y,2026-11-01,{bad',
        'Task 1: subtasks is not valid JSON',
      );
      expectFormatError(
        codec,
        'id,title,createdAt\nx,y,2026-11-01\nx,z,2026-11-01',
        contains('Duplicate'),
      );
    });
  });

  test('detect picks JSON for objects, CSV otherwise', () {
    expect(BackupFormat.detect('  {"a":1}'), BackupFormat.json);
    expect(BackupFormat.detect('id,title'), BackupFormat.csv);
  });

  test('fileName includes date, time and extension', () {
    final now = DateTime(2026, 3, 7, 9, 5);
    expect(
      BackupFormat.json.fileName(now),
      'task_tracker_2026-03-07_0905.json',
    );
    expect(BackupFormat.csv.fileName(now), 'task_tracker_2026-03-07_0905.csv');
  });
}
