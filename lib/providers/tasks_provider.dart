import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/subtask.dart';
import '../data/models/task.dart';
import '../data/repositories/task_repository.dart';
import 'repository_providers.dart';

/// All tasks (every status, including Messy Can). Screens derive their own
/// views from this list.
final tasksProvider = NotifierProvider<TasksNotifier, List<Task>>(
  TasksNotifier.new,
);

class TasksNotifier extends Notifier<List<Task>> {
  TaskRepository get _repo => ref.read(taskRepositoryProvider);
  DateTime _now() => ref.read(clockProvider)();

  @override
  List<Task> build() {
    final repo = ref.watch(taskRepositoryProvider);
    // Keep in sync with writes made outside this notifier (e.g. imports).
    final sub = repo.watch().listen((_) => _reload());
    ref.onDispose(sub.cancel);
    return repo.getAll();
  }

  void _reload() {
    if (ref.mounted) state = _repo.getAll();
  }

  Task? byId(String id) {
    for (final t in state) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Creates and stores a new task; returns it.
  Future<Task> add({
    required String title,
    String description = '',
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    String category = 'Personal',
    List<String> labels = const [],
    DateTime? dueDate,
    List<Subtask> subtasks = const [],
  }) async {
    final task = Task.create(
      title: title.trim(),
      now: _now(),
      description: description,
      status: status,
      priority: priority,
      category: category,
      labels: labels,
      dueDate: dueDate,
      subtasks: subtasks,
    );
    await _repo.upsert(task);
    _reload();
    return task;
  }

  /// Saves an edited task and bumps `updatedAt`.
  Future<void> save(Task task) async {
    await _repo.upsert(task.copyWith(updatedAt: _now()));
    _reload();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _reload();
  }

  /// Moves a task to another status (board drag, promote from Messy Can).
  Future<void> moveTo(String id, TaskStatus status) async {
    final task = byId(id);
    if (task == null || task.status == status) return;
    await save(task.copyWith(status: status));
  }

  /// Checks a task off (→ Done) or un-checks it (→ To Do).
  Future<void> setDone(String id, bool done) =>
      moveTo(id, done ? TaskStatus.done : TaskStatus.todo);

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    final task = byId(taskId);
    if (task == null) return;
    await save(
      task.copyWith(
        subtasks: [
          for (final s in task.subtasks)
            s.id == subtaskId ? s.copyWith(isDone: !s.isDone) : s,
        ],
      ),
    );
  }
}
