import 'package:flutter_application_3_11/data/services/backup_io.dart';

/// Keeps "saved" files in memory.
class FakeBackupFileStore implements BackupFileStore {
  final files = <String, String>{};

  @override
  Future<String> save(String fileName, String content) async {
    final path = '/docs/$fileName';
    files[path] = content;
    return path;
  }
}

/// Records share requests instead of opening the share sheet.
class FakeBackupSharer implements BackupSharer {
  final shared = <({String path, String mimeType})>[];

  @override
  Future<void> shareFile(
    String path, {
    required String mimeType,
    required String subject,
  }) async => shared.add((path: path, mimeType: mimeType));
}

/// Returns [text] as if the user picked a file (null = cancelled).
class FakeBackupFilePicker implements BackupFilePicker {
  FakeBackupFilePicker(this.text);

  String? text;

  @override
  Future<String?> pickText() async => text;
}
