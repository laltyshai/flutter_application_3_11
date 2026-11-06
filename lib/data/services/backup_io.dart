import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Platform side of backups (files, share sheet, file picker), behind small
/// interfaces so tests can pass fakes.

abstract interface class BackupFileStore {
  /// Writes [content] to a file named [fileName]; returns its full path.
  Future<String> save(String fileName, String content);
}

abstract interface class BackupSharer {
  /// Opens the system share sheet for the file at [path].
  Future<void> shareFile(
    String path, {
    required String mimeType,
    required String subject,
  });
}

abstract interface class BackupFilePicker {
  /// Lets the user pick a `.json`/`.csv` file; returns its text, or `null`
  /// when cancelled.
  Future<String?> pickText();
}

/// Saves into the app's documents directory.
class DocumentsBackupFileStore implements BackupFileStore {
  const DocumentsBackupFileStore();

  @override
  Future<String> save(String fileName, String content) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(content, flush: true);
    return file.path;
  }
}

/// Android share intent via `share_plus`.
class SystemBackupSharer implements BackupSharer {
  const SystemBackupSharer();

  @override
  Future<void> shareFile(
    String path, {
    required String mimeType,
    required String subject,
  }) => SharePlus.instance.share(
    ShareParams(
      files: [XFile(path, mimeType: mimeType)],
      subject: subject,
    ),
  );
}

/// System file picker via `file_picker`.
class SystemBackupFilePicker implements BackupFilePicker {
  const SystemBackupFilePicker();

  @override
  Future<String?> pickText() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json', 'csv'],
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    try {
      return utf8.decode(bytes);
    } on FormatException {
      throw const FormatException('The file is not UTF-8 text');
    }
  }
}
