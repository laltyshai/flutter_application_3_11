import 'package:flutter/material.dart';
import 'package:flutter_application_3_11/core/theme/app_theme.dart';
import 'package:flutter_application_3_11/data/models/subtask.dart';
import 'package:flutter_application_3_11/data/models/task.dart';
import 'package:flutter_application_3_11/ui/widgets/priority_indicator.dart';
import 'package:flutter_application_3_11/ui/widgets/task_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 5, 9);

  Task task({
    TaskStatus status = TaskStatus.todo,
    DateTime? dueDate,
    List<Subtask> subtasks = const [],
  }) => Task(
    id: 't1',
    title: 'Write report',
    status: status,
    priority: TaskPriority.high,
    category: 'Work',
    dueDate: dueDate,
    subtasks: subtasks,
    createdAt: now,
    updatedAt: now,
  );

  Future<void> pumpCard(
    WidgetTester tester,
    Task t, {
    VoidCallback? onTap,
    ValueChanged<bool>? onDoneChanged,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: TaskCard(
          task: t,
          now: now,
          onTap: onTap,
          onDoneChanged: onDoneChanged,
        ),
      ),
    ),
  );

  testWidgets('shows title, category and priority', (tester) async {
    await pumpCard(tester, task());

    expect(find.text('Write report'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    // The card's InkWell merges child labels into one node.
    expect(find.bySemanticsLabel(RegExp('High priority')), findsOneWidget);
    final indicator = tester.widget<PriorityIndicator>(
      find.byType(PriorityIndicator),
    );
    expect(indicator.priority, TaskPriority.high);
  });

  testWidgets('shows subtask ratio only when there are subtasks', (
    tester,
  ) async {
    await pumpCard(tester, task());
    expect(find.byIcon(Icons.checklist), findsNothing);

    await pumpCard(
      tester,
      task(
        subtasks: const [
          Subtask(id: 'a', title: 'a', isDone: true),
          Subtask(id: 'b', title: 'b'),
          Subtask(id: 'c', title: 'c'),
        ],
      ),
    );
    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('due date: relative label, overdue only while pending', (
    tester,
  ) async {
    await pumpCard(tester, task(dueDate: DateTime(2026, 11, 6)));
    expect(find.text('Tomorrow'), findsOneWidget);

    await pumpCard(tester, task(dueDate: DateTime(2026, 11, 1)));
    expect(find.text('Overdue · Nov 1'), findsOneWidget);

    await pumpCard(
      tester,
      task(dueDate: DateTime(2026, 11, 1), status: TaskStatus.done),
    );
    expect(find.text('Nov 1'), findsOneWidget);
    expect(find.textContaining('Overdue'), findsNothing);
  });

  testWidgets('calls onTap', (tester) async {
    var taps = 0;
    await pumpCard(tester, task(), onTap: () => taps++);

    await tester.tap(find.byType(TaskCard));
    expect(taps, 1);
  });

  testWidgets('no checkbox unless onDoneChanged is given', (tester) async {
    await pumpCard(tester, task());
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('checkbox sits on the right and reports ticks', (tester) async {
    final calls = <bool>[];
    var taps = 0;
    await pumpCard(
      tester,
      task(),
      onTap: () => taps++,
      onDoneChanged: calls.add,
    );

    final box = tester.getRect(find.byType(Checkbox));
    final card = tester.getRect(find.byType(TaskCard));
    final title = tester.getRect(find.text('Write report'));
    expect(box.left, greaterThanOrEqualTo(title.right));
    expect(box.center.dx, greaterThan(card.center.dx));
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(
      find.bySemanticsLabel('Mark "Write report" as done'),
      findsOneWidget,
    );

    await tester.tap(find.byType(Checkbox));
    expect(calls, [true]);
    expect(taps, 0); // ticking doesn't open the task
  });

  testWidgets('done task shows a ticked box; clearing it reports false', (
    tester,
  ) async {
    final calls = <bool>[];
    await pumpCard(
      tester,
      task(status: TaskStatus.done),
      onDoneChanged: calls.add,
    );
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    await tester.tap(find.byType(Checkbox));
    expect(calls, [false]);
  });
}
