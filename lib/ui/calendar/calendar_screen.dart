import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_utils.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/repository_providers.dart';
import '../../providers/task_editor_provider.dart';
import '../../providers/tasks_provider.dart';
import '../task/task_editor_screen.dart';
import 'agenda_list.dart';
import 'quick_add_bar.dart';
import 'task_calendar.dart';

/// Day-by-day agenda: calendar on top, tasks due on the selected day below,
/// and a quick-add bar for that day at the bottom.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendar = ref.watch(calendarProvider);
    final notifier = ref.read(calendarProvider.notifier);
    final byDay = ref.watch(tasksByDayProvider);
    final agenda = ref.watch(selectedDayTasksProvider);
    final now = ref.watch(clockProvider)();
    final day = calendar.selectedDay;
    final nextSpan = calendar.span == CalendarSpan.month
        ? CalendarSpan.week
        : CalendarSpan.month;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            tooltip: 'Go to today',
            icon: const Icon(Icons.today_outlined),
            onPressed: notifier.goToToday,
          ),
          IconButton(
            tooltip: 'Show ${nextSpan.label.toLowerCase()}',
            icon: Icon(
              nextSpan == CalendarSpan.week
                  ? Icons.view_week_outlined
                  : Icons.calendar_view_month_outlined,
            ),
            onPressed: () => notifier.setSpan(nextSpan),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            // Calendar and agenda scroll together so short screens still
            // reach the agenda; the quick-add bar stays pinned below.
            child: ListView(
              children: [
                TaskCalendar(
                  selectedDay: day,
                  focusedDay: calendar.focusedDay,
                  today: AppDates.dayOf(now),
                  span: calendar.span,
                  taskCountOf: (d) => byDay[d]?.length ?? 0,
                  onDaySelected: notifier.selectDay,
                  onPageChanged: notifier.showPage,
                ),
                const Divider(height: 1),
                AgendaList(
                  title: AppDates.formatLongDay(day, now),
                  tasks: agenda,
                  now: now,
                  onOpen: (task) => TaskEditorScreen.open(
                    context,
                    TaskEditorArgs.edit(task.id),
                  ),
                  onDoneChanged: (task, done) =>
                      ref.read(tasksProvider.notifier).setDone(task.id, done),
                ),
              ],
            ),
          ),
          QuickAddBar(
            dayLabel: AppDates.formatRelative(day, now),
            onAdd: notifier.quickAdd,
          ),
        ],
      ),
    );
  }
}
