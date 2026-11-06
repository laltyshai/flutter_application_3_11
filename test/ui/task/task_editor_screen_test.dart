import 'package:flutter/material.dart';
import 'package:flutter_application_3_11/data/db/hive_setup.dart';
import 'package:flutter_application_3_11/data/models/task.dart';
import 'package:flutter_application_3_11/providers/tasks_provider.dart';
import 'package:flutter_application_3_11/ui/board/board_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_hive.dart';

void main() {
  late HiveBoxes boxes;
  setUp(() async => boxes = await openMemoryHive());
  tearDown(() => closeMemoryHive(boxes));

  Finder saveButton() => find.widgetWithText(FilledButton, 'Save');

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('create a task from the board', (tester) async {
    final container = await tester.pumpApp(const BoardScreen(), boxes: boxes);

    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();
    expect(find.text('New task'), findsOneWidget); // editor app bar
    expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Buy plants',
    );
    await tester.pump();
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'High'));
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Chores'));

    final subtaskField = find.widgetWithText(TextField, 'Add a subtask');
    await tester.ensureVisible(subtaskField);
    await tester.enterText(subtaskField, 'Pick pots');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Pick pots'), findsOneWidget);

    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    // Back on the board with the new card.
    expect(find.text('Buy plants'), findsOneWidget);
    expect(find.text('0/1'), findsOneWidget);
    final task = container.read(tasksProvider).single;
    expect(task.priority, TaskPriority.high);
    expect(task.category, 'Chores');
    expect(task.subtasks.single.title, 'Pick pots');
  });

  testWidgets('back with unsaved changes asks before discarding', (
    tester,
  ) async {
    final container = await tester.pumpApp(const BoardScreen(), boxes: boxes);
    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'Draft',
    );
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Draft'), findsOneWidget); // still editing

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('No tasks yet'), findsOneWidget);
    expect(container.read(tasksProvider), isEmpty);
  });

  testWidgets('edit and delete an existing task', (tester) async {
    final container = await tester.pumpApp(const BoardScreen(), boxes: boxes);
    await container.read(tasksProvider.notifier).add(title: 'Old title');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Old title'));
    await tester.pumpAndSettle();
    expect(find.text('Edit task'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'New title',
    );
    await tester.pump();
    await tester.tap(saveButton());
    await tester.pumpAndSettle();
    expect(find.text('New title'), findsOneWidget);

    await tester.tap(find.text('New title'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete task'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('No tasks yet'), findsOneWidget);
    expect(container.read(tasksProvider), isEmpty);
  });
}
