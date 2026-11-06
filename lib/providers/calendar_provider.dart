import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_utils.dart';
import '../data/models/task.dart';
import 'repository_providers.dart';
import 'tasks_provider.dart';

/// How many weeks the calendar shows at once.
enum CalendarSpan {
  week('Week'),
  month('Month');

  const CalendarSpan(this.label);
  final String label;
}

/// Selected day, the page the calendar shows ([focusedDay]) and its span.
/// Days are always local midnight.
@immutable
class CalendarState {
  const CalendarState({
    required this.selectedDay,
    required this.focusedDay,
    this.span = CalendarSpan.month,
  });

  final DateTime selectedDay;
  final DateTime focusedDay;
  final CalendarSpan span;

  CalendarState copyWith({
    DateTime? selectedDay,
    DateTime? focusedDay,
    CalendarSpan? span,
  }) => CalendarState(
    selectedDay: selectedDay ?? this.selectedDay,
    focusedDay: focusedDay ?? this.focusedDay,
    span: span ?? this.span,
  );

  @override
  bool operator ==(Object other) =>
      other is CalendarState &&
      other.selectedDay == selectedDay &&
      other.focusedDay == focusedDay &&
      other.span == span;

  @override
  int get hashCode => Object.hash(selectedDay, focusedDay, span);
}

final calendarProvider = NotifierProvider<CalendarNotifier, CalendarState>(
  CalendarNotifier.new,
);

class CalendarNotifier extends Notifier<CalendarState> {
  DateTime _today() => AppDates.dayOf(ref.read(clockProvider)());

  @override
  CalendarState build() {
    final today = _today();
    return CalendarState(selectedDay: today, focusedDay: today);
  }

  /// Selects [day] (any time of day; only its date fields are used).
  void selectDay(DateTime day) {
    final d = AppDates.dayOf(day);
    state = state.copyWith(selectedDay: d, focusedDay: d);
  }

  /// The calendar was swiped to another week/month.
  void showPage(DateTime focusedDay) =>
      state = state.copyWith(focusedDay: AppDates.dayOf(focusedDay));

  void goToToday() => selectDay(_today());

  void setSpan(CalendarSpan span) => state = state.copyWith(span: span);

  /// Creates a To Do task due on the selected day. Blank titles are ignored.
  Future<void> quickAdd(String title) async {
    if (title.trim().isEmpty) return;
    await ref
        .read(tasksProvider.notifier)
        .add(title: title, dueDate: state.selectedDay);
  }
}

/// Board tasks with a due date, grouped by the local day they are due.
/// Each day's list is sorted: unfinished first, then priority, then oldest.
Map<DateTime, List<Task>> groupByDueDay(Iterable<Task> tasks) {
  final byDay = <DateTime, List<Task>>{};
  for (final t in tasks) {
    final due = t.dueDate;
    if (due == null || t.isMessyCan) continue;
    byDay.putIfAbsent(AppDates.localDayOf(due), () => []).add(t);
  }
  for (final list in byDay.values) {
    list.sort(_agendaOrder);
  }
  return byDay;
}

int _agendaOrder(Task a, Task b) {
  final done =
      (a.status == TaskStatus.done ? 1 : 0) -
      (b.status == TaskStatus.done ? 1 : 0);
  if (done != 0) return done;
  final priority = a.priority.index.compareTo(b.priority.index);
  if (priority != 0) return priority;
  return a.createdAt.compareTo(b.createdAt);
}

final tasksByDayProvider = Provider<Map<DateTime, List<Task>>>(
  (ref) => groupByDueDay(ref.watch(tasksProvider)),
);

/// Agenda for the selected day.
final selectedDayTasksProvider = Provider<List<Task>>((ref) {
  final day = ref.watch(calendarProvider.select((s) => s.selectedDay));
  return ref.watch(tasksByDayProvider)[day] ?? const [];
});
