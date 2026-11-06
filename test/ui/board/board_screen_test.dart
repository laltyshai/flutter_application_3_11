import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3_11/data/db/hive_setup.dart';
import 'package:flutter_application_3_11/data/models/task.dart';
import 'package:flutter_application_3_11/providers/tasks_provider.dart';
import 'package:flutter_application_3_11/ui/board/board_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_hive.dart';

void main() {
  late HiveBoxes boxes;
  setUp(() async => boxes = await openMemoryHive());
  tearDown(() => closeMemoryHive(boxes));

  Future<ProviderContainer> pumpBoard(
    WidgetTester tester,
    List<({String title, TaskStatus status, TaskPriority priority})> seed,
  ) async {
    final container = await tester.pumpApp(const BoardScreen(), boxes: boxes);
    for (final t in seed) {
      await container
          .read(tasksProvider.notifier)
          .add(title: t.title, status: t.status, priority: t.priority);
    }
    await tester.pumpAndSettle();
    return container;
  }

  ({String title, TaskStatus status, TaskPriority priority}) seed(
    String title, {
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
  }) => (title: title, status: status, priority: priority);

  Task byTitle(ProviderContainer c, String title) =>
      c.read(tasksProvider).firstWhere((t) => t.title == title);

  testWidgets('shows columns with task counts', (tester) async {
    await pumpBoard(tester, [
      seed('A'),
      seed('B'),
      seed('C', status: TaskStatus.inProgress),
    ]);

    expect(find.bySemanticsLabel('To Do, 2 tasks'), findsOneWidget);
    expect(find.bySemanticsLabel('In Progress, 1 tasks'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('long-press drag to the edge moves a card to the next column', (
    tester,
  ) async {
    final container = await pumpBoard(tester, [seed('Drag me')]);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Drag me')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

    // Near the right edge: the board flips to In Progress.
    final board = tester.getRect(find.byType(PageView));
    await gesture.moveTo(Offset(board.right - 10, board.center.dy));
    await tester.pump();
    await tester.pumpAndSettle();

    // Drop in the middle of the now-centered In Progress column.
    await gesture.moveTo(tester.getCenter(find.byType(PageView)));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(byTitle(container, 'Drag me').status, TaskStatus.inProgress);
    expect(find.bySemanticsLabel('In Progress, 1 tasks'), findsOneWidget);
  });

  testWidgets('filter sheet filters cards and shows removable chips', (
    tester,
  ) async {
    await pumpBoard(tester, [
      seed('Urgent', priority: TaskPriority.high),
      seed('Someday', priority: TaskPriority.low),
    ]);

    await tester.tap(find.byTooltip('Filter & sort'));
    await tester.pumpAndSettle();
    expect(find.text('Filter & sort'), findsWidgets);
    await tester.tap(find.widgetWithText(FilterChip, 'High'));
    await tester.pumpAndSettle();
    final done = find.widgetWithText(FilledButton, 'Done');
    await tester.ensureVisible(done);
    await tester.pumpAndSettle();
    await tester.tap(done);
    await tester.pumpAndSettle();

    expect(find.text('Urgent'), findsOneWidget);
    expect(find.text('Someday'), findsNothing);
    expect(find.widgetWithText(InputChip, 'High priority'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove High priority filter'));
    await tester.pumpAndSettle();
    expect(find.text('Someday'), findsOneWidget);
    expect(find.byType(InputChip), findsNothing);
  });

  testWidgets('random pick: Start moves the task to In Progress', (
    tester,
  ) async {
    final container = await pumpBoard(tester, [
      seed('Only one'),
      seed('Finished', status: TaskStatus.done),
    ]);

    await tester.tap(find.byTooltip('Pick a random task'));
    await tester.pumpAndSettle();
    expect(find.text('Your Next Task to Tackle!'), findsOneWidget);
    final dialog = find.byType(AlertDialog);
    expect(
      find.descendant(of: dialog, matching: find.text('Only one')),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(byTitle(container, 'Only one').status, TaskStatus.inProgress);
  });

  testWidgets('random pick: Pick again shows a different task', (tester) async {
    final container = await tester.pumpApp(const BoardScreen(), boxes: boxes);
    for (final title in ['First', 'Second']) {
      await container.read(tasksProvider.notifier).add(title: title);
    }
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Pick a random task'));
    await tester.pumpAndSettle();
    String shown() => tester
        .widget<Text>(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byWidgetPredicate(
              (w) => w is Text && (w.data == 'First' || w.data == 'Second'),
            ),
          ),
        )
        .data!;
    final first = shown();

    await tester.tap(find.text('Pick again'));
    await tester.pumpAndSettle();
    expect(shown(), isNot(first));
  });

  testWidgets('random pick with nothing pending shows a message', (
    tester,
  ) async {
    await pumpBoard(tester, [seed('Finished', status: TaskStatus.done)]);

    await tester.tap(find.byTooltip('Pick a random task'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.text('No To Do or In Progress tasks to pick from.'),
      findsOneWidget,
    );
  });
}
