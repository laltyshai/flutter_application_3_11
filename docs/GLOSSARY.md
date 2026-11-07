# Glossary

Terms used in this codebase and in explanations. Each entry points to real code.

## App data

| Term | Meaning | In code |
|---|---|---|
| **Task** | One to-do item with all its fields (title, status, priority, …). Saved in Hive. | `lib/data/models/task.dart` |
| **Subtask** | A checklist line inside a task. Stored inside its task. | `lib/data/models/subtask.dart` |
| **Status** | Which column/area a task is in: To Do, In Progress, Done, Messy Can. | `TaskStatus` |
| **Draft** | An unsaved copy of a task's fields while you edit it. Becomes a real `Task` only when you press Save. | `TaskDraft` in `lib/providers/task_editor_provider.dart` |
| **Box** | A Hive storage file, like one table. We have a `tasks` box and a `settings` box. | `lib/data/db/hive_setup.dart` |
| **Board filter** | The chosen labels/categories/priorities plus sort order for the board. Inside one group any value matches; all groups must match. | `BoardFilter` in `lib/data/models/board_filter.dart` |
| **Comparator** | A function `(a, b) → int` that says which of two tasks comes first (negative = `a` first). Each sort mode has one. | `TaskSortField.compare` |
| **Repository** | A class that reads and writes one kind of data in a box. Nothing else talks to Hive directly. | `TaskRepository`, `SettingsRepository` |

## Riverpod (state management)

| Term | Meaning | In code |
|---|---|---|
| **State** | The data a screen shows right now. When it changes, the screen redraws. | `List<Task>` for `tasksProvider`; `TaskEditorState` for the editor |
| **Notifier** | A class that owns one piece of state and is the only place allowed to change it. `build()` returns the starting state; its methods change it by assigning `state = …`. | `TasksNotifier`, `TaskEditorNotifier` |
| **Provider** | A global variable that tells Riverpod how to create a notifier (or a value) and lets any widget find it by name. | `tasksProvider`, `taskEditorProvider` |
| **Container / ProviderScope** | Where Riverpod keeps the notifiers it has created, so everyone asking for the same provider gets the same one. | `ProviderScope` in `lib/main.dart` |
| **ref** | The handle a widget or notifier uses to talk to Riverpod. | `WidgetRef ref` in `build` |
| **ref.watch(p)** | Get the current value **and** redraw this widget whenever it changes. Use in `build`. | `ref.watch(boardColumnsProvider)` |
| **ref.read(p)** | Get the value once, no redraw. Use in button callbacks and inside notifiers. | `ref.read(provider.notifier).save()` |
| **ref.listen(p, …)** | Run a callback on every change, without redrawing. Also keeps the provider alive. | `container.listen(...)` in tests |
| **`.notifier`** | `ref.read(p)` gives the *state*; `ref.read(p.notifier)` gives the *notifier* so you can call its methods. | `ref.read(taskEditorProvider(args).notifier)` |
| **Derived provider** | A provider whose value is computed from other providers and recomputes when they change. | `boardColumnsProvider` (from `tasksProvider` + `boardFilterProvider`) |
| **Family** | A provider that takes an argument. Riverpod keeps one separate notifier per distinct argument value. | `taskEditorProvider(args)` |
| **Argument (args)** | The value passed to a family; it decides which notifier you get. | `TaskEditorArgs.edit(id)`, `TaskEditorArgs.create()` |
| **autoDispose** | Riverpod deletes the notifier (and its state) as soon as nothing is watching or listening to it. | `NotifierProvider.autoDispose.family` |
| **Override** | Replace a provider's value, e.g. with real Hive boxes in `main`, or test boxes and a fixed clock in tests. | `hiveBoxesProvider.overrideWithValue(boxes)` |

## Dart

| Term | Meaning | In code |
|---|---|---|
| **Immutable** | An object whose fields never change after creation; to "change" it you make a new copy. | all models, `TaskEditorState` |
| **copyWith** | Makes a copy of an immutable object with some fields replaced. | `task.copyWith(title: 'New')` |
| **`==` / `hashCode`** | How Dart decides two objects count as "the same". By default only the exact same object is equal; overriding compares the fields instead. Maps (and Riverpod families) look keys up with these. | `TaskEditorArgs`, `Task` |
| **Stateless / Stateful widget** | A stateless widget only draws what it's given. A stateful widget keeps its own changing data (we use it only for text controllers and the selected tab). | `TaskCard` vs `AddItemField` |

## Flutter widgets (board)

| Term | Meaning | In code |
|---|---|---|
| **PageView** | A horizontally swipeable list where each child fills one "page". The board shows one column per page. | `KanbanBoard` in `lib/ui/board/kanban_board.dart` |
| **PageController** | Object that knows which page a `PageView` is on and can move it (`animateToPage`). | `_KanbanBoardState._controller` |
| **LongPressDraggable** | Wraps a widget so a long press picks it up and it follows your finger; carries a value (`data`). | each card in `lib/ui/board/kanban_column.dart` |
| **DragTarget** | An area that accepts a dragged value when you let go over it. | each `KanbanColumn` accepts a `Task` and calls `onMove` |
| **Bottom sheet** | A panel that slides up from the bottom of the screen. | `FilterSortSheet.show` |
| **Seeded Random** | `Random(42)` always produces the same sequence, so tests of random picking are repeatable. | `randomProvider` override in `test/providers/board_provider_test.dart` |

## Dates & calendar

| Term | Meaning | In code |
|---|---|---|
| **Local day** | The calendar date a moment falls on in the phone's time zone, stored as local midnight. Used as the key for grouping tasks by day. | `AppDates.localDayOf`, `groupByDueDay` |
| **UTC** | Time-zone-free "world time". A `DateTime` parsed from a string ending in `Z` is UTC; `table_calendar` also hands out days as UTC midnight. `.toLocal()` converts to phone time. | `AppDates.localDayOf` vs `AppDates.dayOf` |
| **Selected / focused day** | Selected = the day whose agenda is shown. Focused = which week/month page the calendar is showing. | `CalendarState` in `lib/providers/calendar_provider.dart` |
| **Agenda** | The list of tasks due on the selected day. | `selectedDayTasksProvider`, `AgendaList` |
| **`select`** | `ref.watch(p.select((s) => s.x))` redraws/recomputes only when that one field changes. | `selectedDayTasksProvider` watches only `selectedDay` |

## Messy Can

| Term | Meaning | In code |
|---|---|---|
| **Idea** | A task with status `messyCan`: a quick thought that isn't on the board yet. | `messyCanProvider` in `lib/providers/messy_can_provider.dart` |
| **Promote** | Move an idea onto the board by changing its status (and choosing priority/due date). | `Promotion`, `MessyCanNotifier.promote`, `PromoteSheet` |
| **Undo (restore)** | After a delete, the deleted `Task` is kept in the snackbar's callback and saved back exactly as it was. | `MessyCanNotifier.undoDelete` → `TasksNotifier.restore` |
| **Dismissible** | Flutter widget that lets you swipe a list item away; `onDismissed` runs after the swipe. | idea list in `lib/ui/messy_can/messy_can_screen.dart` |
| **Record** | A small unnamed bundle of values, like `(title: 'x', note: 'y')`. Used to return two values from a dialog without a new class. | `showIdeaEditDialog` |

## Backup

| Term | Meaning | In code |
|---|---|---|
| **Codec** | A pair of functions that turn data into text (`encode`) and back (`decode`). One per file format. | `BackupCodec`, `JsonBackupCodec`, `CsvBackupCodec` |
| **Schema version** | A number saying which layout the stored/backup data uses, so old backups can be migrated and newer ones rejected. | `SettingsRepository.currentSchemaVersion` |
| **Restore** | Delete all current data and replace it with the backup. | `ImportMode.restore`, `TasksNotifier.replaceAll` |
| **Merge** | Keep current data; add tasks with new ids and overwrite ones whose backup copy has a later `updatedAt`. | `ImportMode.merge`, `tasksToMerge` |
| **Preview** | Counts shown before importing: total, new, existing, newer. | `ImportPreview` |
| **Interface / fake** | An `abstract interface class` lists methods without code; the app uses a real implementation (file system, share sheet) and tests pass a fake one that records calls. | `BackupFileStore` / `FakeBackupFileStore` |
| **Share intent** | Android's "Share to…" sheet that sends a file to another app. | `SystemBackupSharer` |

## Settings

| Term | Meaning | In code |
|---|---|---|
| **Board layout** | How the board shows statuses: Rows (each status a horizontal strip of cards, up to 2 rows, swipe sideways) or Columns (each status a page you swipe between). Saved in settings. | `BoardLayout`, `KanbanRows`, `KanbanBoard` |
| **Setting choice** | A reusable card that shows every option of a setting as a row of buttons; one tap changes it, no dialog. Settings uses it for Theme and Board layout. | `SettingChoice` in `lib/ui/widgets/setting_choice.dart` |
| **Segmented button** | Flutter's row of joined buttons where exactly one is selected. | `SegmentedButton` inside `SettingChoice` |
| **Theme mode** | Which colors the app uses: System (follow the phone), Light or Dark. Saved in the settings box and read by `MaterialApp.themeMode`. | `AppSettings.themeMode`, `lib/app.dart`, `showThemeModeDialog` |
