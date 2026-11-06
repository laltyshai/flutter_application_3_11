import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/task.dart';
import 'random_provider.dart';
import 'tasks_provider.dart';

/// Where a promoted idea goes on the board.
@immutable
class Promotion {
  const Promotion({
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.dueDate,
  }) : assert(status != TaskStatus.messyCan, 'Promote to a board column');

  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;

  static const Object _unset = Object();

  Promotion copyWith({
    TaskStatus? status,
    TaskPriority? priority,
    Object? dueDate = _unset,
  }) => Promotion(
    status: status ?? this.status,
    priority: priority ?? this.priority,
    dueDate: identical(dueDate, _unset) ? this.dueDate : dueDate as DateTime?,
  );

  @override
  bool operator ==(Object other) =>
      other is Promotion &&
      other.status == status &&
      other.priority == priority &&
      other.dueDate == dueDate;

  @override
  int get hashCode => Object.hash(status, priority, dueDate);
}

/// Ideas in the Messy Can (status == messyCan), newest first, plus the
/// actions on them. The tasks themselves live in [tasksProvider].
final messyCanProvider = NotifierProvider<MessyCanNotifier, List<Task>>(
  MessyCanNotifier.new,
);

class MessyCanNotifier extends Notifier<List<Task>> {
  TasksNotifier get _tasks => ref.read(tasksProvider.notifier);

  @override
  List<Task> build() => [
    for (final t in ref.watch(tasksProvider))
      if (t.isMessyCan) t,
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Drops a new idea in the can. Blank titles are ignored.
  Future<Task?> add(String title, {String note = ''}) async {
    if (title.trim().isEmpty) return null;
    return _tasks.add(
      title: title,
      description: note.trim(),
      status: TaskStatus.messyCan,
    );
  }

  /// Quick edit of title and note. Blank titles are ignored.
  Future<void> edit(String id, {required String title, String note = ''}) {
    final idea = _tasks.byId(id);
    if (idea == null || title.trim().isEmpty) return Future.value();
    return _tasks.save(
      idea.copyWith(title: title.trim(), description: note.trim()),
    );
  }

  /// Deletes an idea and returns it, so the UI can offer "Undo".
  Future<Task?> delete(String id) async {
    final idea = _tasks.byId(id);
    if (idea == null) return null;
    await _tasks.delete(id);
    return idea;
  }

  /// Puts a deleted idea back exactly as it was.
  Future<void> undoDelete(Task idea) => _tasks.restore(idea);

  /// Moves an idea out of the can onto the board.
  Future<void> promote(String id, Promotion to) {
    final idea = _tasks.byId(id);
    if (idea == null) return Future.value();
    return _tasks.save(
      idea.copyWith(
        status: to.status,
        priority: to.priority,
        dueDate: to.dueDate,
      ),
    );
  }
}

/// Random idea from the can ("Randomizer").
final ideaPickerProvider = Provider<RandomTaskPicker>(
  (ref) =>
      RandomTaskPicker(ref.watch(messyCanProvider), ref.watch(randomProvider)),
);
