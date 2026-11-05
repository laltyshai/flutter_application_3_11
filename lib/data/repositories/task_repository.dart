import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../models/task.dart';

/// Reads and writes [Task]s in a Hive box (key = id, value = JSON string).
class TaskRepository {
  TaskRepository(this._box);

  final Box<String> _box;

  /// All stored tasks. A corrupt entry is skipped (and logged) rather than
  /// breaking the whole list.
  List<Task> getAll() {
    final tasks = <Task>[];
    for (final key in _box.keys) {
      final task = _decode(key, _box.get(key));
      if (task != null) tasks.add(task);
    }
    return tasks;
  }

  Task? getById(String id) => _decode(id, _box.get(id));

  /// Emits whenever the box changes (from this repository or elsewhere,
  /// e.g. a backup import).
  Stream<void> watch() => _box.watch().map((_) {});

  Future<void> upsert(Task task) => _box.put(task.id, jsonEncode(task));

  Future<void> upsertAll(Iterable<Task> tasks) =>
      _box.putAll({for (final t in tasks) t.id: jsonEncode(t)});

  Future<void> delete(String id) => _box.delete(id);

  Future<void> clear() => _box.clear();

  /// Clears the box, then writes [tasks]. Not atomic, so callers must fully
  /// validate [tasks] before calling (the backup import does).
  Future<void> replaceAll(Iterable<Task> tasks) async {
    await _box.clear();
    await upsertAll(tasks);
  }

  Task? _decode(Object? key, String? raw) {
    if (raw == null) return null;
    try {
      return Task.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('TaskRepository: skipping corrupt task "$key": $e');
      return null;
    }
  }
}
