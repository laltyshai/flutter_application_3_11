import 'package:intl/intl.dart';

/// Calendar-day helpers. All comparisons ignore the time of day.
abstract final class AppDates {
  /// Midnight of [d]'s day.
  static DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Whole days from [now]'s day to [d]'s day (negative = in the past).
  static int daysFrom(DateTime now, DateTime d) =>
      dayOf(d).difference(dayOf(now)).inDays;

  /// True when [due] is on a day before [now]'s day.
  static bool isOverdue(DateTime due, DateTime now) => daysFrom(now, due) < 0;

  /// "Today", "Tomorrow", "Yesterday", "Nov 10", or "Nov 10, 2027" when the
  /// year differs from [now]'s.
  static String formatRelative(DateTime d, DateTime now) {
    switch (daysFrom(now, d)) {
      case 0:
        return 'Today';
      case 1:
        return 'Tomorrow';
      case -1:
        return 'Yesterday';
    }
    final pattern = d.year == now.year ? 'MMM d' : 'MMM d, y';
    return DateFormat(pattern).format(d);
  }
}
