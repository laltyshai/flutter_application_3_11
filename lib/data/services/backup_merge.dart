import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/task.dart';

/// How an import is applied.
enum ImportMode {
  /// Clear everything, then write the backup.
  restore('Restore'),

  /// Keep existing data; add new tasks and update ones that are newer in
  /// the backup (by `updatedAt`).
  merge('Merge');

  const ImportMode(this.label);
  final String label;
}

/// What an import would do, shown before the user confirms.
@immutable
class ImportPreview {
  const ImportPreview({
    required this.total,
    required this.newCount,
    required this.existingCount,
    required this.newerCount,
  });

  factory ImportPreview.of({
    required Iterable<Task> current,
    required Iterable<Task> incoming,
  }) {
    final byId = {for (final t in current) t.id: t};
    var total = 0, fresh = 0, newer = 0;
    for (final t in incoming) {
      total++;
      final mine = byId[t.id];
      if (mine == null) {
        fresh++;
      } else if (t.updatedAt.isAfter(mine.updatedAt)) {
        newer++;
      }
    }
    return ImportPreview(
      total: total,
      newCount: fresh,
      existingCount: total - fresh,
      newerCount: newer,
    );
  }

  final int total;

  /// Tasks whose id isn't stored yet.
  final int newCount;

  /// Tasks whose id is already stored.
  final int existingCount;

  /// Existing tasks the backup has a newer version of (merge updates these).
  final int newerCount;

  /// e.g. "12 tasks, 3 new, 9 existing".
  String get summary =>
      '$total ${total == 1 ? 'task' : 'tasks'}, $newCount new, '
      '$existingCount existing';

  @override
  bool operator ==(Object other) =>
      other is ImportPreview &&
      other.total == total &&
      other.newCount == newCount &&
      other.existingCount == existingCount &&
      other.newerCount == newerCount;

  @override
  int get hashCode => Object.hash(total, newCount, existingCount, newerCount);
}

/// Tasks a merge should write: new ids, plus existing ids where the
/// incoming copy has a later `updatedAt` (newer wins; ties keep ours).
List<Task> tasksToMerge({
  required Iterable<Task> current,
  required Iterable<Task> incoming,
}) {
  final byId = {for (final t in current) t.id: t};
  return [
    for (final t in incoming)
      if (byId[t.id] == null || t.updatedAt.isAfter(byId[t.id]!.updatedAt)) t,
  ];
}

/// Merge keeps the current theme and adds any categories/labels from the
/// backup that aren't there yet (case-insensitive).
AppSettings mergeSettings(AppSettings current, AppSettings? incoming) {
  if (incoming == null) return current;
  return current.copyWith(
    categories: _union(current.categories, incoming.categories),
    labels: _union(current.labels, incoming.labels),
  );
}

List<String> _union(List<String> mine, List<String> theirs) {
  final seen = {for (final s in mine) s.toLowerCase()};
  return [
    ...mine,
    for (final s in theirs)
      if (seen.add(s.toLowerCase())) s,
  ];
}
