import 'package:flutter_application_3_11/core/utils/date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 5, 23, 59);

  test('daysFrom ignores the time of day', () {
    expect(AppDates.daysFrom(now, DateTime(2026, 11, 6, 0, 1)), 1);
    expect(AppDates.daysFrom(now, DateTime(2026, 11, 5, 0, 0)), 0);
    expect(AppDates.daysFrom(now, DateTime(2026, 11, 4, 23, 59)), -1);
  });

  test('isOverdue only for earlier days', () {
    expect(AppDates.isOverdue(DateTime(2026, 11, 5, 8), now), isFalse);
    expect(AppDates.isOverdue(DateTime(2026, 11, 4), now), isTrue);
  });

  test('formatRelative', () {
    expect(AppDates.formatRelative(DateTime(2026, 11, 5), now), 'Today');
    expect(AppDates.formatRelative(DateTime(2026, 11, 6), now), 'Tomorrow');
    expect(AppDates.formatRelative(DateTime(2026, 11, 4), now), 'Yesterday');
    expect(AppDates.formatRelative(DateTime(2026, 11, 20), now), 'Nov 20');
    expect(AppDates.formatRelative(DateTime(2027, 1, 2), now), 'Jan 2, 2027');
  });

  test('isSameDay and dayOf', () {
    expect(AppDates.isSameDay(DateTime(2026, 11, 5, 1), now), isTrue);
    expect(AppDates.dayOf(now), DateTime(2026, 11, 5));
  });
}
