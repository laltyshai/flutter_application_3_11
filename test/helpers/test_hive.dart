import 'dart:typed_data';
import 'dart:io';

import 'package:flutter_application_3_11/data/db/hive_setup.dart';
import 'package:hive_ce/hive.dart';

/// Hive in a throwaway temp directory, one per test.
class TestHive {
  TestHive._(this._dir, this.boxes);

  final Directory _dir;
  final HiveBoxes boxes;

  static Future<TestHive> open() async {
    final dir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(dir.path);
    final boxes = await HiveSetup.openBoxes();
    return TestHive._(dir, boxes);
  }

  /// Opens the tasks box again after it was closed (persistence checks).
  static Future<Box<String>> reopenTasks() =>
      Hive.openBox<String>(HiveSetup.tasksBoxName);

  Future<void> dispose() async {
    await Hive.close();
    await _dir.delete(recursive: true);
  }
}

/// In-memory Hive boxes (no disk I/O), safe inside `testWidgets`' fake clock.
/// Open in `setUp`, close with [closeMemoryHive] in `tearDown`.
Future<HiveBoxes> openMemoryHive() async {
  final id = _memoryBoxCounter++;
  final boxes = await Future.wait([
    Hive.openBox<String>('mem_tasks_$id', bytes: Uint8List(0)),
    Hive.openBox<String>('mem_settings_$id', bytes: Uint8List(0)),
  ]);
  return HiveBoxes(tasks: boxes[0], settings: boxes[1]);
}

Future<void> closeMemoryHive(HiveBoxes boxes) async {
  await boxes.tasks.close();
  await boxes.settings.close();
}

int _memoryBoxCounter = 0;
