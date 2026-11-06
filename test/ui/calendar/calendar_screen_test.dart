import 'package:flutter/material.dart';
import 'package:flutter_application_3_11/data/db/hive_setup.dart';
import 'package:flutter_application_3_11/data/models/task.dart';
import 'package:flutter_application_3_11/providers/tasks_provider.dart';
import 'package:flutter_application_3_11/ui/calendar/calendar_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_hive.dart';

void main() {
  late HiveBoxes boxes;
  setUp(() async => boxes = await openMemoryHive());
  tearDown(() => closeMemoryHive(boxes));

  Finder dayCell(String day) => find.descendant(
    of: find.byType(TableCalendar<int>),
    matching: find.text(day),
  );

  testWidgets('shows today\'s agenda and switches days', (tester) async {
    final container = await tester.pumpApp(
      const CalendarScreen(),
      boxes: boxes,
    );
    final tasks = container.read(tasksProvider.notifier);
    await tasks.add(title: 'Today task', dueDate: DateTime(2026, 11, 5, 18));
    await tasks.add(title: 'Later task', dueDate: DateTime(2026, 11, 10));
    await tester.pumpAndSettle();

    // testNow is Thu 5 Nov 2026.
    expect(find.text('Thursday, Nov 5 · 1'), findsOneWidget);
    expect(find.text('Today task'), findsOneWidget);
    expect(find.text('Later task'), findsNothing);

    await tester.tap(dayCell('10'));
    await tester.pumpAndSettle();
    expect(find.text('Tuesday, Nov 10 · 1'), findsOneWidget);
    expect(find.text('Later task'), findsOneWidget);
    expect(find.text('Today task'), findsNothing);

    await tester.tap(dayCell('11'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing scheduled'), findsOneWidget);

    await tester.tap(find.byTooltip('Go to today'));
    await tester.pumpAndSettle();
    expect(find.text('Today task'), findsOneWidget);
  });

  testWidgets('quick-add creates a task on the selected day', (tester) async {
    final container = await tester.pumpApp(
      const CalendarScreen(),
      boxes: boxes,
    );

    await tester.tap(dayCell('12'));
    await tester.pumpAndSettle();
    final field = find.widgetWithText(TextField, 'Add a task for Nov 12');
    expect(field, findsOneWidget);

    await tester.enterText(field, 'Dentist');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final task = container.read(tasksProvider).single;
    expect(task.title, 'Dentist');
    expect(task.status, TaskStatus.todo);
    expect(task.dueDate, DateTime(2026, 11, 12));
    expect(find.text('Dentist'), findsOneWidget);
  });

  testWidgets('checkbox marks a task done', (tester) async {
    final container = await tester.pumpApp(
      const CalendarScreen(),
      boxes: boxes,
    );
    await container
        .read(tasksProvider.notifier)
        .add(title: 'Water plants', dueDate: DateTime(2026, 11, 5));
    await tester.pumpAndSettle();

    final checkbox = find.byType(Checkbox);
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();

    expect(container.read(tasksProvider).single.status, TaskStatus.done);
    expect(tester.widget<Checkbox>(checkbox).value, isTrue);
  });

  testWidgets('toggles between month and week view', (tester) async {
    await tester.pumpApp(const CalendarScreen(), boxes: boxes);
    CalendarFormat format() => tester
        .widget<TableCalendar<int>>(find.byType(TableCalendar<int>))
        .calendarFormat;

    expect(format(), CalendarFormat.month);
    await tester.tap(find.byTooltip('Show week'));
    await tester.pumpAndSettle();
    expect(format(), CalendarFormat.week);
    await tester.tap(find.byTooltip('Show month'));
    await tester.pumpAndSettle();
    expect(format(), CalendarFormat.month);
  });
}
