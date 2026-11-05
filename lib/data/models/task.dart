import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'subtask.dart';

enum TaskStatus {
  todo('To Do'),
  inProgress('In Progress'),
  done('Done'),
  messyCan('Messy Can');

  const TaskStatus(this.label);
  final String label;

  /// Statuses shown as columns on the Kanban board.
  static const boardColumns = [todo, inProgress, done];

  /// Parses a stored name; unknown values fall back to [todo].
  static TaskStatus fromName(Object? name) =>
      values.firstWhere((s) => s.name == name, orElse: () => todo);
}

enum TaskPriority {
  // Declared high → low so `index` can be used for sorting.
  high('High'),
  medium('Medium'),
  low('Low');

  const TaskPriority(this.label);
  final String label;

  /// Parses a stored name; unknown values fall back to [medium].
  static TaskPriority fromName(Object? name) =>
      values.firstWhere((p) => p.name == name, orElse: () => medium);
}

/// Sentinel so `copyWith(dueDate: null)` can clear the due date.
const Object _unset = Object();

@immutable
class Task {
  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.category = 'Personal',
    List<String> labels = const [],
    this.dueDate,
    List<Subtask> subtasks = const [],
    required this.createdAt,
    required this.updatedAt,
  }) : labels = List.unmodifiable(labels),
       subtasks = List.unmodifiable(subtasks);

  /// New task with a fresh UUID; [now] sets both `createdAt` and `updatedAt`.
  factory Task.create({
    required String title,
    required DateTime now,
    String description = '',
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    String category = 'Personal',
    List<String> labels = const [],
    DateTime? dueDate,
    List<Subtask> subtasks = const [],
  }) => Task(
    id: const Uuid().v4(),
    title: title,
    description: description,
    status: status,
    priority: priority,
    category: category,
    labels: labels,
    dueDate: dueDate,
    subtasks: subtasks,
    createdAt: now,
    updatedAt: now,
  );

  /// Throws [FormatException] when required fields are missing or malformed.
  factory Task.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    if (id is! String || id.isEmpty || title is! String) {
      throw FormatException('Invalid task: missing id or title');
    }
    final createdAt = _parseDate(json['createdAt'], 'createdAt');
    if (createdAt == null) {
      throw const FormatException('Invalid task: missing createdAt');
    }
    return Task(
      id: id,
      title: title,
      description: json['description'] as String? ?? '',
      status: TaskStatus.fromName(json['status']),
      priority: TaskPriority.fromName(json['priority']),
      category: json['category'] as String? ?? 'Personal',
      labels: [
        for (final l in json['labels'] as List? ?? const [])
          if (l is String) l,
      ],
      dueDate: _parseDate(json['dueDate'], 'dueDate'),
      subtasks: [
        for (final s in json['subtasks'] as List? ?? const [])
          Subtask.fromJson(Map<String, dynamic>.from(s as Map)),
      ],
      createdAt: createdAt,
      updatedAt: _parseDate(json['updatedAt'], 'updatedAt') ?? createdAt,
    );
  }

  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final String category;
  final List<String> labels;
  final DateTime? dueDate;
  final List<Subtask> subtasks;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get completedSubtasks => subtasks.where((s) => s.isDone).length;

  /// Shown on cards as `completed/total`, e.g. `2/5`.
  String get subtaskRatio => '$completedSubtasks/${subtasks.length}';

  bool get isMessyCan => status == TaskStatus.messyCan;

  /// To Do or In Progress — candidates for the random picker.
  bool get isPending =>
      status == TaskStatus.todo || status == TaskStatus.inProgress;

  Task copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? category,
    List<String>? labels,
    Object? dueDate = _unset,
    List<Subtask>? subtasks,
    DateTime? updatedAt,
  }) => Task(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    category: category ?? this.category,
    labels: labels ?? this.labels,
    dueDate: identical(dueDate, _unset) ? this.dueDate : dueDate as DateTime?,
    subtasks: subtasks ?? this.subtasks,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'status': status.name,
    'priority': priority.name,
    'category': category,
    'labels': labels,
    'dueDate': dueDate?.toIso8601String(),
    'subtasks': [for (final s in subtasks) s.toJson()],
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static DateTime? _parseDate(Object? value, String field) {
    if (value == null) return null;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Invalid task: bad $field "$value"');
  }

  @override
  bool operator ==(Object other) =>
      other is Task &&
      other.id == id &&
      other.title == title &&
      other.description == description &&
      other.status == status &&
      other.priority == priority &&
      other.category == category &&
      listEquals(other.labels, labels) &&
      other.dueDate == dueDate &&
      listEquals(other.subtasks, subtasks) &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    status,
    priority,
    category,
    Object.hashAll(labels),
    dueDate,
    Object.hashAll(subtasks),
    createdAt,
    updatedAt,
  );

  @override
  String toString() => 'Task($id, $title, ${status.name})';
}
