import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_application_3_11/data/models/app_settings.dart';
import 'package:flutter_application_3_11/data/models/subtask.dart';
import 'package:flutter_application_3_11/data/models/task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final created = DateTime(2026, 11, 5, 9, 30);

  Task fullTask() => Task(
    id: 'task-1',
    title: 'Write report',
    description: 'Quarterly numbers',
    status: TaskStatus.inProgress,
    priority: TaskPriority.high,
    category: 'Work',
    labels: const ['urgent', 'q4'],
    dueDate: DateTime(2026, 11, 10),
    subtasks: const [
      Subtask(id: 's1', title: 'Collect data', isDone: true),
      Subtask(id: 's2', title: 'Draft'),
    ],
    createdAt: created,
    updatedAt: created.add(const Duration(hours: 1)),
  );

  group('Task', () {
    test('JSON round-trip keeps every field', () {
      final task = fullTask();
      expect(Task.fromJson(task.toJson()), task);
    });

    test('enums are stored by name', () {
      final json = fullTask().toJson();
      expect(json['status'], 'inProgress');
      expect(json['priority'], 'high');
    });

    test('fromJson fills defaults for optional fields', () {
      final task = Task.fromJson({
        'id': 'x',
        'title': 'Minimal',
        'createdAt': created.toIso8601String(),
      });
      expect(task.status, TaskStatus.todo);
      expect(task.priority, TaskPriority.medium);
      expect(task.labels, isEmpty);
      expect(task.subtasks, isEmpty);
      expect(task.dueDate, isNull);
      expect(task.updatedAt, created);
    });

    test('fromJson falls back on unknown enum names', () {
      final json = fullTask().toJson()
        ..['status'] = 'archived'
        ..['priority'] = 'urgent';
      final task = Task.fromJson(json);
      expect(task.status, TaskStatus.todo);
      expect(task.priority, TaskPriority.medium);
    });

    test('fromJson rejects missing id, title or createdAt', () {
      final base = fullTask().toJson();
      for (final field in ['id', 'title', 'createdAt']) {
        final json = Map<String, dynamic>.of(base)..remove(field);
        expect(() => Task.fromJson(json), throwsFormatException, reason: field);
      }
    });

    test('fromJson rejects a malformed date', () {
      final json = fullTask().toJson()..['dueDate'] = 'next tuesday';
      expect(() => Task.fromJson(json), throwsFormatException);
    });

    test('copyWith can clear dueDate and keeps it when omitted', () {
      final task = fullTask();
      expect(task.copyWith(title: 'New').dueDate, task.dueDate);
      expect(task.copyWith(dueDate: null).dueDate, isNull);
    });

    test('subtask ratio and pending flags', () {
      final task = fullTask();
      expect(task.subtaskRatio, '1/2');
      expect(task.isPending, isTrue);
      expect(task.copyWith(status: TaskStatus.done).isPending, isFalse);
      expect(task.copyWith(status: TaskStatus.messyCan).isMessyCan, isTrue);
    });

    test('Task.create assigns a UUID and equal timestamps', () {
      final a = Task.create(title: 'A', now: created);
      final b = Task.create(title: 'B', now: created);
      expect(a.id, hasLength(36));
      expect(a.id, isNot(b.id));
      expect(a.createdAt, created);
      expect(a.updatedAt, created);
    });

    test('lists are unmodifiable', () {
      expect(() => fullTask().labels.add('x'), throwsUnsupportedError);
      expect(
        () => fullTask().subtasks.add(Subtask.create('x')),
        throwsUnsupportedError,
      );
    });
  });

  group('AppSettings', () {
    test('defaults seed the README categories', () {
      expect(
        AppSettings().categories,
        containsAll(['Work', 'Chores', 'Personal']),
      );
      expect(AppSettings().themeMode, ThemeMode.system);
    });

    test('JSON round-trip', () {
      final settings = AppSettings(
        themeMode: ThemeMode.dark,
        categories: const ['Work', 'Garden'],
        labels: const ['urgent'],
      );
      expect(AppSettings.fromJson(settings.toJson()), settings);
    });
  });
}
