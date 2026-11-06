import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/subtask.dart';
import '../data/models/task.dart';
import 'settings_provider.dart';
import 'tasks_provider.dart';

/// What the editor opens: an existing task ([taskId]) or a new one with
/// optional presets (e.g. the calendar's selected day, or Messy Can status).
@immutable
class TaskEditorArgs {
  const TaskEditorArgs.edit(String this.taskId)
    : initialStatus = null,
      initialDueDate = null;

  const TaskEditorArgs.create({this.initialStatus, this.initialDueDate})
    : taskId = null;

  final String? taskId;
  final TaskStatus? initialStatus;
  final DateTime? initialDueDate;

  bool get isNew => taskId == null;

  @override
  bool operator ==(Object other) =>
      other is TaskEditorArgs &&
      other.taskId == taskId &&
      other.initialStatus == initialStatus &&
      other.initialDueDate == initialDueDate;

  @override
  int get hashCode => Object.hash(taskId, initialStatus, initialDueDate);
}

/// The editable fields of a task, before it is saved.
@immutable
class TaskDraft {
  TaskDraft({
    this.title = '',
    this.description = '',
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.category = 'Personal',
    List<String> labels = const [],
    this.dueDate,
    List<Subtask> subtasks = const [],
  }) : labels = List.unmodifiable(labels),
       subtasks = List.unmodifiable(subtasks);

  factory TaskDraft.fromTask(Task t) => TaskDraft(
    title: t.title,
    description: t.description,
    status: t.status,
    priority: t.priority,
    category: t.category,
    labels: t.labels,
    dueDate: t.dueDate,
    subtasks: t.subtasks,
  );

  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final String category;
  final List<String> labels;
  final DateTime? dueDate;
  final List<Subtask> subtasks;

  /// `completed/total`, e.g. `2/5`.
  String get subtaskRatio =>
      '${subtasks.where((s) => s.isDone).length}/${subtasks.length}';

  static const Object _unset = Object();

  TaskDraft copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    String? category,
    List<String>? labels,
    Object? dueDate = _unset,
    List<Subtask>? subtasks,
  }) => TaskDraft(
    title: title ?? this.title,
    description: description ?? this.description,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    category: category ?? this.category,
    labels: labels ?? this.labels,
    dueDate: identical(dueDate, _unset) ? this.dueDate : dueDate as DateTime?,
    subtasks: subtasks ?? this.subtasks,
  );

  @override
  bool operator ==(Object other) =>
      other is TaskDraft &&
      other.title == title &&
      other.description == description &&
      other.status == status &&
      other.priority == priority &&
      other.category == category &&
      listEquals(other.labels, labels) &&
      other.dueDate == dueDate &&
      listEquals(other.subtasks, subtasks);

  @override
  int get hashCode => Object.hash(
    title,
    description,
    status,
    priority,
    category,
    Object.hashAll(labels),
    dueDate,
    Object.hashAll(subtasks),
  );
}

@immutable
class TaskEditorState {
  const TaskEditorState({
    required this.initial,
    required this.draft,
    required this.isNew,
    this.notFound = false,
  });

  /// The draft as it was when the editor opened (for "unsaved changes").
  final TaskDraft initial;
  final TaskDraft draft;
  final bool isNew;

  /// The task being edited no longer exists (e.g. deleted elsewhere).
  final bool notFound;

  bool get isDirty => draft != initial;
  bool get canSave => !notFound && draft.title.trim().isNotEmpty;

  TaskEditorState withDraft(TaskDraft d) => TaskEditorState(
    initial: initial,
    draft: d,
    isNew: isNew,
    notFound: notFound,
  );

  @override
  bool operator ==(Object other) =>
      other is TaskEditorState &&
      other.initial == initial &&
      other.draft == draft &&
      other.isNew == isNew &&
      other.notFound == notFound;

  @override
  int get hashCode => Object.hash(initial, draft, isNew, notFound);
}

/// One editor per [TaskEditorArgs]; disposed when the editor screen closes.
final taskEditorProvider = NotifierProvider.autoDispose
    .family<TaskEditorNotifier, TaskEditorState, TaskEditorArgs>(
      TaskEditorNotifier.new,
    );

class TaskEditorNotifier extends Notifier<TaskEditorState> {
  TaskEditorNotifier(this.args);

  final TaskEditorArgs args;

  TasksNotifier get _tasks => ref.read(tasksProvider.notifier);

  @override
  TaskEditorState build() {
    final taskId = args.taskId;
    if (taskId == null) {
      final settings = ref.read(settingsProvider);
      final draft = TaskDraft(
        status: args.initialStatus ?? TaskStatus.todo,
        dueDate: args.initialDueDate,
        category: settings.categories.isNotEmpty
            ? settings.categories.first
            : 'Personal',
      );
      return TaskEditorState(initial: draft, draft: draft, isNew: true);
    }
    final task = _tasks.byId(taskId);
    final draft = task == null ? TaskDraft() : TaskDraft.fromTask(task);
    return TaskEditorState(
      initial: draft,
      draft: draft,
      isNew: false,
      notFound: task == null,
    );
  }

  void _update(TaskDraft Function(TaskDraft d) change) =>
      state = state.withDraft(change(state.draft));

  void setTitle(String v) => _update((d) => d.copyWith(title: v));
  void setDescription(String v) => _update((d) => d.copyWith(description: v));
  void setStatus(TaskStatus v) => _update((d) => d.copyWith(status: v));
  void setPriority(TaskPriority v) => _update((d) => d.copyWith(priority: v));
  void setCategory(String v) => _update((d) => d.copyWith(category: v));
  void setDueDate(DateTime? v) => _update((d) => d.copyWith(dueDate: v));

  /// Adds a trimmed label unless blank or already present (case-insensitive).
  void addLabel(String label) {
    final trimmed = label.trim();
    final lower = trimmed.toLowerCase();
    if (trimmed.isEmpty ||
        state.draft.labels.any((l) => l.toLowerCase() == lower)) {
      return;
    }
    _update((d) => d.copyWith(labels: [...d.labels, trimmed]));
  }

  void removeLabel(String label) => _update(
    (d) => d.copyWith(labels: d.labels.where((l) => l != label).toList()),
  );

  void addSubtask(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    _update(
      (d) => d.copyWith(subtasks: [...d.subtasks, Subtask.create(trimmed)]),
    );
  }

  void toggleSubtask(String id) => _update(
    (d) => d.copyWith(
      subtasks: [
        for (final s in d.subtasks)
          s.id == id ? s.copyWith(isDone: !s.isDone) : s,
      ],
    ),
  );

  void removeSubtask(String id) => _update(
    (d) => d.copyWith(subtasks: d.subtasks.where((s) => s.id != id).toList()),
  );

  /// Saves the draft (create or update). Returns false if it can't be saved.
  /// New labels and categories are remembered in settings for suggestions.
  Future<bool> save() async {
    if (!state.canSave) return false;
    final d = state.draft;
    final settings = ref.read(settingsProvider.notifier);
    for (final label in d.labels) {
      await settings.addLabel(label);
    }
    await settings.addCategory(d.category);

    final taskId = args.taskId;
    if (taskId == null) {
      await _tasks.add(
        title: d.title,
        description: d.description.trim(),
        status: d.status,
        priority: d.priority,
        category: d.category,
        labels: d.labels,
        dueDate: d.dueDate,
        subtasks: d.subtasks,
      );
    } else {
      final original = _tasks.byId(taskId);
      if (original == null) return false;
      await _tasks.save(
        original.copyWith(
          title: d.title.trim(),
          description: d.description.trim(),
          status: d.status,
          priority: d.priority,
          category: d.category,
          labels: d.labels,
          dueDate: d.dueDate,
          subtasks: d.subtasks,
        ),
      );
    }
    if (ref.mounted) {
      state = TaskEditorState(initial: d, draft: d, isNew: state.isNew);
    }
    return true;
  }

  /// Deletes the task being edited (no-op for a new task).
  Future<void> delete() async {
    final taskId = args.taskId;
    if (taskId != null) await _tasks.delete(taskId);
  }
}
