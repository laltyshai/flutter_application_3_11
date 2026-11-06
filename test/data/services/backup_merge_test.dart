import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_application_3_11/data/models/app_settings.dart';
import 'package:flutter_application_3_11/data/models/task.dart';
import 'package:flutter_application_3_11/data/services/backup_merge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 11, 1);

  Task task(String id, {int updatedHour = 0, String title = 't'}) => Task(
    id: id,
    title: title,
    createdAt: t0,
    updatedAt: t0.add(Duration(hours: updatedHour)),
  );

  final current = [task('a', updatedHour: 5), task('b', updatedHour: 5)];
  final incoming = [
    task('a', updatedHour: 9, title: 'newer'), // newer → update
    task('b', updatedHour: 5, title: 'tie'), // same time → keep ours
    task('c'), // new
  ];

  test('preview counts new, existing and newer tasks', () {
    final p = ImportPreview.of(current: current, incoming: incoming);
    expect(
      p,
      const ImportPreview(
        total: 3,
        newCount: 1,
        existingCount: 2,
        newerCount: 1,
      ),
    );
    expect(p.summary, '3 tasks, 1 new, 2 existing');
    expect(
      ImportPreview.of(current: const [], incoming: [task('x')]).summary,
      '1 task, 1 new, 0 existing',
    );
  });

  test('merge writes new tasks and newer copies; ties and older keep ours', () {
    final older = [task('a', updatedHour: 1, title: 'older')];
    expect(
      tasksToMerge(current: current, incoming: incoming).map((t) => t.title),
      ['newer', 't'],
    );
    expect(tasksToMerge(current: current, incoming: older), isEmpty);
  });

  test('settings merge unions categories/labels and keeps our theme', () {
    final mine = AppSettings(
      themeMode: ThemeMode.dark,
      categories: const ['Work'],
      labels: const ['Home'],
    );
    final theirs = AppSettings(
      themeMode: ThemeMode.light,
      categories: const ['work', 'Garden'],
      labels: const ['home', 'diy'],
    );
    final merged = mergeSettings(mine, theirs);
    expect(merged.themeMode, ThemeMode.dark);
    expect(merged.categories, ['Work', 'Garden']);
    expect(merged.labels, ['Home', 'diy']);
    expect(mergeSettings(mine, null), mine);
  });
}
