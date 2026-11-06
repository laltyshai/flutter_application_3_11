import 'dart:convert';

import 'package:csv/csv.dart';

import '../models/backup_data.dart';
import '../models/task.dart';
import '../repositories/settings_repository.dart';
import 'backup_codec.dart';

/// One row per task (spreadsheet-friendly). Labels are joined with `|`,
/// subtasks are an embedded JSON string. Settings are not included.
class CsvBackupCodec implements BackupCodec {
  const CsvBackupCodec();

  static const labelSeparator = '|';

  static const columns = [
    'id',
    'title',
    'description',
    'status',
    'priority',
    'category',
    'labels',
    'dueDate',
    'subtasks',
    'createdAt',
    'updatedAt',
  ];

  static const _required = ['id', 'title', 'createdAt'];

  static final _csv = Csv(lineDelimiter: '\n', autoDetect: false);

  @override
  String encode(BackupData data) => _csv.encode([
    columns,
    for (final t in data.tasks)
      [
        t.id,
        t.title,
        t.description,
        t.status.name,
        t.priority.name,
        t.category,
        t.labels.join(labelSeparator),
        t.dueDate?.toIso8601String() ?? '',
        jsonEncode([for (final s in t.subtasks) s.toJson()]),
        t.createdAt.toIso8601String(),
        t.updatedAt.toIso8601String(),
      ],
  ]);

  @override
  BackupData decode(String text) {
    final rows = _csv.decode(text.replaceFirst('﻿', ''));
    if (rows.isEmpty) throw const FormatException('The CSV is empty');

    final header = [for (final h in rows.first) '$h'.trim()];
    for (final name in _required) {
      if (!header.contains(name)) {
        throw FormatException('CSV header is missing the "$name" column');
      }
    }

    final tasks = [
      for (var i = 1; i < rows.length; i++)
        decodeTaskAt(i - 1, () => _rowToTask(header, rows[i])),
    ];
    return BackupData(
      schemaVersion: SettingsRepository.currentSchemaVersion,
      exportedAt: null,
      tasks: validateTasks(tasks),
    );
  }

  static Task _rowToTask(List<String> header, List<dynamic> row) {
    String? cell(String name) {
      final i = header.indexOf(name);
      if (i < 0 || i >= row.length) return null;
      final value = '${row[i]}';
      return value.isEmpty ? null : value;
    }

    final subtasks = cell('subtasks');
    final Object? decodedSubtasks;
    try {
      decodedSubtasks = subtasks == null ? null : jsonDecode(subtasks);
    } on FormatException {
      throw const FormatException('subtasks is not valid JSON');
    }
    if (decodedSubtasks != null && decodedSubtasks is! List) {
      throw const FormatException('subtasks must be a JSON list');
    }

    return Task.fromJson({
      'id': cell('id'),
      'title': cell('title'),
      'description': cell('description'),
      'status': cell('status'),
      'priority': cell('priority'),
      'category': cell('category'),
      'labels': cell('labels')?.split(labelSeparator) ?? const <String>[],
      'dueDate': cell('dueDate'),
      'subtasks': decodedSubtasks,
      'createdAt': cell('createdAt'),
      'updatedAt': cell('updatedAt'),
    });
  }
}
