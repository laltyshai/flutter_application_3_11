import 'package:hive_ce_flutter/hive_flutter.dart';

/// Opened Hive boxes. Values are JSON-encoded strings, so no type adapters
/// or code generation are needed.
class HiveBoxes {
  const HiveBoxes({required this.tasks, required this.settings});

  /// key = task id, value = task JSON.
  final Box<String> tasks;

  /// Holds [SettingsRepository] keys (settings JSON, schema version).
  final Box<String> settings;
}

abstract final class HiveSetup {
  static const tasksBoxName = 'tasks';
  static const settingsBoxName = 'settings';

  /// Call once before `runApp`.
  static Future<HiveBoxes> init() async {
    await Hive.initFlutter();
    return openBoxes();
  }

  /// Opens the app boxes. Assumes Hive is already initialized
  /// (by [init] in the app, or `Hive.init(path)` in tests).
  static Future<HiveBoxes> openBoxes({String prefix = ''}) async {
    final boxes = await Future.wait([
      Hive.openBox<String>('$prefix$tasksBoxName'),
      Hive.openBox<String>('$prefix$settingsBoxName'),
    ]);
    return HiveBoxes(tasks: boxes[0], settings: boxes[1]);
  }
}
