import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../providers/calendar_provider.dart';

/// Week/month calendar with a dot under days that have tasks.
/// Renders [selectedDay]/[focusedDay] and forwards taps and swipes.
class TaskCalendar extends StatelessWidget {
  const TaskCalendar({
    super.key,
    required this.selectedDay,
    required this.focusedDay,
    required this.today,
    required this.span,
    required this.taskCountOf,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final DateTime selectedDay;
  final DateTime focusedDay;
  final DateTime today;
  final CalendarSpan span;

  /// Number of tasks due on a day (local midnight); drives the markers.
  final int Function(DateTime day) taskCountOf;

  /// Days come from the calendar as UTC midnight; only their date fields
  /// are meaningful (the notifier normalizes them).
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onPageChanged;

  static const _formats = {
    CalendarSpan.week: CalendarFormat.week,
    CalendarSpan.month: CalendarFormat.month,
  };

  /// Calendar day fields → local midnight, matching the provider's keys.
  static DateTime _local(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final format = _formats[span]!;

    return TableCalendar<int>(
      firstDay: DateTime(today.year - 5),
      lastDay: DateTime(today.year + 5, 12, 31),
      focusedDay: focusedDay,
      currentDay: today,
      calendarFormat: format,
      availableCalendarFormats: {format: span.label},
      startingDayOfWeek: StartingDayOfWeek.monday,
      rowHeight: 44,
      selectedDayPredicate: (d) => isSameDay(d, selectedDay),
      // One marker per day is enough: the count is shown in the agenda.
      eventLoader: (d) => taskCountOf(_local(d)) > 0 ? const [1] : const [],
      onDaySelected: (selected, _) => onDaySelected(selected),
      onPageChanged: onPageChanged,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: theme.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: scheme.secondaryContainer,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(color: scheme.onSecondaryContainer),
        selectedDecoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
        markerDecoration: BoxDecoration(
          color: scheme.onSurface,
          shape: BoxShape.circle,
        ),
        markerSize: 5,
      ),
    );
  }
}
