import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_3_11/data/db/hive_setup.dart';
import 'package:flutter_application_3_11/data/models/app_settings.dart';
import 'package:flutter_application_3_11/data/models/task.dart';
import 'package:flutter_application_3_11/providers/board_provider.dart';
import 'package:flutter_application_3_11/providers/settings_provider.dart';
import 'package:flutter_application_3_11/providers/tasks_provider.dart';
import 'package:flutter_application_3_11/ui/board/board_screen.dart';
import 'package:flutter_application_3_11/ui/board/kanban_board.dart';
import 'package:flutter_application_3_11/ui/board/kanban_rows.dart';
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
    List<({String title, TaskStatus status, TaskPriority priority})> seed, {
    BoardLayout layout = BoardLayout.rows,
  }) async {
    final container = await tester.pumpApp(const BoardScreen(), boxes: boxes);
    await container.read(settingsProvider.notifier).setBoardLayout(layout);
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

  testWidgets('rows layout is the default', (tester) async {
    final container = await tester.pumpApp(const BoardScreen(), boxes: boxes);
    await container.read(tasksProvider.notifier).add(title: 'A');
    await tester.pumpAndSettle();
    expect(find.byType(KanbanRows), findsOneWidget);
    expect(find.byType(KanbanBoard), findsNothing);
  });

  testWidgets('rows: statuses with counts, cards split into two rows', (
    tester,
  ) async {
    final container = await pumpBoard(tester, [
      for (final t in ['A', 'B', 'C']) seed(t),
      seed('D', status: TaskStatus.inProgress),
    ]);

    expect(find.bySemanticsLabel('To Do, 3 tasks'), findsOneWidget);
    expect(find.bySemanticsLabel('In Progress, 1 tasks'), findsOneWidget);
    // 3 To Do cards → two rows: first row has 2 cards, second row 1.
    final ys = {
      for (final t in ['A', 'B', 'C']) t: tester.getTopLeft(find.text(t)).dy,
    };
    expect(ys.values.toSet(), hasLength(2));
    // Board order [first, second, third]: first and third share the top
    // row, second is below (cards are dealt column by column).
    final order = [
      for (final t in container.read(boardColumnsProvider)[TaskStatus.todo]!)
        t.title,
    ];
    expect(ys[order[0]], ys[order[2]]);
    expect(ys[order[1]]!, greaterThan(ys[order[0]]!));

    // Done is below the fold on the 800x600 test screen.
    await tester.scrollUntilVisible(
      find.text('No tasks'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('No tasks'), findsOneWidget);
  });

  testWidgets('rows: long-press drag a card onto another status', (
    tester,
  ) async {
    final container = await pumpBoard(tester, [
      seed('Drag me'),
      seed('Doing', status: TaskStatus.inProgress),
    ]);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Drag me')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(tester.getCenter(find.text('Doing')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(byTitle(container, 'Drag me').status, TaskStatus.inProgress);
    expect(find.bySemanticsLabel('In Progress, 2 tasks'), findsOneWidget);
  });

  testWidgets('rows: tapping a card opens the editor', (tester) async {
    await pumpBoard(tester, [seed('Open me')]);
    await tester.tap(find.text('Open me'));
    await tester.pumpAndSettle();
    expect(find.text('Edit task'), findsOneWidget);
  });

  testWidgets('rows: ticking the card checkbox moves it to Done', (
    tester,
  ) async {
    final container = await pumpBoard(tester, [seed('Finish me')]);

    await tester.tap(find.bySemanticsLabel('Mark "Finish me" as done'));
    await tester.pumpAndSettle();
    expect(byTitle(container, 'Finish me').status, TaskStatus.done);

    // Clearing it on the Done card sends it back to To Do.
    final undo = find.bySemanticsLabel('Mark "Finish me" as not done');
    await tester.ensureVisible(undo);
    await tester.pumpAndSettle();
    await tester.tap(undo);
    await tester.pumpAndSettle();
    expect(byTitle(container, 'Finish me').status, TaskStatus.todo);
  });

  testWidgets('columns: ticking the card checkbox moves it to Done', (
    tester,
  ) async {
    final container = await pumpBoard(tester, [
      seed('Column task'),
    ], layout: BoardLayout.columns);

    await tester.tap(find.bySemanticsLabel('Mark "Column task" as done'));
    await tester.pumpAndSettle();
    expect(byTitle(container, 'Column task').status, TaskStatus.done);
  });

  testWidgets('shows columns with task counts', (tester) async {
    await pumpBoard(tester, [
      seed('A'),
      seed('B'),
      seed('C', status: TaskStatus.inProgress),
    ], layout: BoardLayout.columns);
    expect(find.byType(KanbanBoard), findsOneWidget);

    expect(find.bySemanticsLabel('To Do, 2 tasks'), findsOneWidget);
    expect(find.bySemanticsLabel('In Progress, 1 tasks'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('long-press drag to the edge moves a card to the next column', (
    tester,
  ) async {
    final container = await pumpBoard(tester, [
      seed('Drag me'),
    ], layout: BoardLayout.columns);

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
      find.descendant(of: dialog, matching: find.byType(Checkbox)),
      findsNothing,
    );
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
