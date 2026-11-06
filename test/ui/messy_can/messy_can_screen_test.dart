import 'package:flutter/material.dart';
import 'package:flutter_application_3_11/data/db/hive_setup.dart';
import 'package:flutter_application_3_11/data/models/task.dart';
import 'package:flutter_application_3_11/providers/messy_can_provider.dart';
import 'package:flutter_application_3_11/providers/tasks_provider.dart';
import 'package:flutter_application_3_11/ui/messy_can/messy_can_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_hive.dart';

void main() {
  late HiveBoxes boxes;
  setUp(() async => boxes = await openMemoryHive());
  tearDown(() => closeMemoryHive(boxes));

  Future<ProviderContainer> pumpCan(
    WidgetTester tester, [
    List<String> ideas = const [],
  ]) async {
    final container = await tester.pumpApp(
      const MessyCanScreen(),
      boxes: boxes,
    );
    for (final title in ideas) {
      await container.read(messyCanProvider.notifier).add(title);
    }
    await tester.pumpAndSettle();
    return container;
  }

  Task only(ProviderContainer c) => c.read(tasksProvider).single;

  testWidgets('fast entry adds an idea with a note', (tester) async {
    final container = await pumpCan(tester);
    expect(find.text('The can is empty'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.casino_outlined),
          )
          .onPressed,
      isNull,
    );

    await tester.enterText(
      find.widgetWithText(TextField, 'Note (optional)'),
      'from the podcast',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Dump an idea…'),
      'Learn pottery',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Learn pottery'), findsOneWidget);
    expect(find.text('from the podcast'), findsOneWidget);
    expect(only(container).status, TaskStatus.messyCan);
    expect(only(container).description, 'from the podcast');
  });

  testWidgets('quick edit changes the title', (tester) async {
    final container = await pumpCan(tester, ['Old idea']);

    await tester.tap(find.text('Old idea'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Idea'), 'New idea');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('New idea'), findsOneWidget);
    expect(only(container).title, 'New idea');
  });

  testWidgets('swipe to delete, then Undo brings it back', (tester) async {
    final container = await pumpCan(tester, ['Swipe me']);

    await tester.drag(find.text('Swipe me'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Swipe me'), findsNothing);
    expect(container.read(tasksProvider), isEmpty);
    expect(find.text('Deleted "Swipe me"'), findsOneWidget);

    await tester.tap(find.widgetWithText(SnackBarAction, 'Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Swipe me'), findsOneWidget);
    expect(only(container).status, TaskStatus.messyCan);
  });

  testWidgets('promote moves the idea to the chosen column and priority', (
    tester,
  ) async {
    final container = await pumpCan(tester, ['Big plan']);

    await tester.tap(find.byTooltip('Promote to board'));
    await tester.pumpAndSettle();
    expect(find.text('Promote to board'), findsWidgets);
    await tester.tap(find.widgetWithText(ChoiceChip, 'In Progress'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'High'));
    await tester.pumpAndSettle();
    final promote = find.widgetWithText(FilledButton, 'Promote');
    await tester.ensureVisible(promote);
    await tester.pumpAndSettle();
    await tester.tap(promote);
    await tester.pumpAndSettle();

    expect(find.text('Big plan'), findsNothing);
    expect(find.text('"Big plan" moved to In Progress'), findsOneWidget);
    expect(only(container).status, TaskStatus.inProgress);
    expect(only(container).priority, TaskPriority.high);
  });

  testWidgets('randomizer with one idea: draw again shows it, then promote', (
    tester,
  ) async {
    final container = await pumpCan(tester, ['Lonely idea']);

    await tester.tap(find.byTooltip('Draw a random idea'));
    await tester.pumpAndSettle();
    expect(find.text('Fished out of the can!'), findsOneWidget);

    await tester.tap(find.text('Draw again'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Lonely idea'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Promote'));
    await tester.pumpAndSettle();
    final promote = find.widgetWithText(FilledButton, 'Promote');
    await tester.ensureVisible(promote);
    await tester.pumpAndSettle();
    await tester.tap(promote);
    await tester.pumpAndSettle();

    expect(only(container).status, TaskStatus.todo);
    expect(find.text('The can is empty'), findsOneWidget);
  });
}
