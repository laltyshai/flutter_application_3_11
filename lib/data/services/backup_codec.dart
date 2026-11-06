import '../models/backup_data.dart';
import '../models/task.dart';
import 'csv_backup_codec.dart';
import 'json_backup_codec.dart';

/// Turns [BackupData] into text and back. One implementation per format.
abstract interface class BackupCodec {
  /// Text for a backup file.
  String encode(BackupData data);

  /// Parses and validates [text]. Throws [FormatException] with a
  /// user-readable message when anything is wrong; never returns partial data.
  BackupData decode(String text);
}

/// Export/import formats. A new format is a new entry plus its codec.
enum BackupFormat {
  json(
    'JSON',
    'Full backup: tasks, ideas and settings.',
    'json',
    'application/json',
    JsonBackupCodec(),
  ),
  csv(
    'CSV',
    'Tasks and ideas only, one row each. Opens in spreadsheets.',
    'csv',
    'text/csv',
    CsvBackupCodec(),
  );

  const BackupFormat(
    this.label,
    this.description,
    this.extension,
    this.mimeType,
    this.codec,
  );

  final String label;
  final String description;
  final String extension;
  final String mimeType;
  final BackupCodec codec;

  /// e.g. `task_tracker_2026-11-05_0900.json`.
  String fileName(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'task_tracker_${now.year}-${two(now.month)}-${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}.$extension';
  }

  /// Guesses the format from the text itself (a JSON backup is an object).
  static BackupFormat detect(String text) =>
      text.trimLeft().startsWith('{') ? json : csv;
}

/// Shared checks for decoded task lists: rejects duplicate ids.
List<Task> validateTasks(List<Task> tasks) {
  final seen = <String>{};
  for (final t in tasks) {
    if (!seen.add(t.id)) {
      throw FormatException('Duplicate task id "${t.id}"');
    }
  }
  return tasks;
}

/// Wraps a per-task error with its position, e.g. "Task 3: bad dueDate".
Task decodeTaskAt(int index, Task Function() decode) {
  try {
    return decode();
  } on FormatException catch (e) {
    throw FormatException('Task ${index + 1}: ${e.message}');
  } on TypeError {
    throw FormatException('Task ${index + 1}: a field has the wrong type');
  }
}
