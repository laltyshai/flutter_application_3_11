# Overall Plan — Local-First To-Do & Task Tracker (Flutter, Android)

Source of requirements: [README.md](../README.md).
Current state: fresh Flutter project (`lib/main.dart` "Hello World", empty `lib/screens/nain_screen.dart`), no dependencies yet. Flutter 3.47.5, Dart SDK `^3.13.4`.

---

## 1. Goal

An offline, single-device Android app to track tasks with four main areas:

1. **Kanban board** (GitHub Projects style) with filter/sort and a "Random Idea Picker".
2. **Calendar** day-by-day agenda with quick add for the selected date.
3. **Messy Can** — an idea dump with CRUD, "promote to task", and a randomizer.
4. **Backup** — export to JSON/CSV (save or share) and import (paste or file pick; restore or merge).

No backend. All data lives in a local database.

---

## 2. Key Decisions

| Area | Choice | Why |
|---|---|---|
| State management | `flutter_riverpod` (`Notifier`, no codegen) | README prefers Riverpod; clean logic/UI split, easy to test |
| Storage | `hive_ce` + `hive_ce_flutter` | Maintained fork of Hive; fast key-value boxes, no SQL schema to migrate. Tasks stored as JSON strings, so no adapter codegen is needed |
| IDs | `uuid` | README requires UUID ids |
| Calendar | `table_calendar` | Ready-made month/week strip with day selection |
| Drag & drop | Built-in `LongPressDraggable` + `DragTarget` on a horizontal `PageView` of columns | Covers both "drag-and-drop" and "horizontal swipe" without extra packages |
| Export / share | `path_provider`, `share_plus` | Write file locally, then Android Share Intent |
| Import | `file_picker` + a paste text field | README asks for both |
| CSV | `csv` | Parse/serialize CSV reliably (quotes, commas in text) |
| Dates | `intl` | Formatting due dates and headers |
| Font | Plus Jakarta Sans, bundled in `assets/fonts/` | Chosen instead of the README's Montserrat (the README's font path only has Plus Jakarta Sans) |

"Messy Can" is modeled as a `TaskStatus` value (per the README's enum), so promoting an idea to the board is just a status change.

---

## 3. Folder Structure

```
lib/
  main.dart                     # init Hive, ProviderScope, runApp
  app.dart                      # MaterialApp, theme, bottom navigation shell
  core/
    theme/app_colors.dart       # pastel pink/blue, off-white, charcoal
    theme/app_theme.dart        # light + dark ThemeData, Plus Jakarta Sans
    utils/random_picker.dart    # shared random selection helper
  data/
    models/task.dart            # Task + enums + toJson/fromJson/copyWith
    models/subtask.dart
    models/app_settings.dart    # theme mode, custom categories/labels
    db/hive_setup.dart          # Hive.initFlutter + open boxes
    repositories/task_repository.dart
    repositories/settings_repository.dart
    services/backup_service.dart  # JSON/CSV export + import (restore/merge)
  providers/
    repository_providers.dart
    tasks_provider.dart          # Notifier<List<Task>> with CRUD, synced to box changes
    filter_provider.dart         # labels/categories/priority filter + sort mode
    board_provider.dart          # derived: filtered + sorted tasks per column
    calendar_provider.dart       # selected day + tasks for that day
    messy_can_provider.dart      # derived: status == messyCan
    settings_provider.dart
  ui/
    shell/home_shell.dart        # NavigationBar: Board · Calendar · Messy Can · Backup
    board/board_screen.dart
    board/kanban_column.dart
    board/filter_sort_sheet.dart
    calendar/calendar_screen.dart
    calendar/quick_add_bar.dart
    messy_can/messy_can_screen.dart
    backup/backup_screen.dart
    backup/import_screen.dart
    task/task_editor_screen.dart # create/edit task incl. subtasks, labels
    widgets/task_card.dart
    widgets/priority_indicator.dart
    widgets/category_badge.dart
    widgets/random_pick_dialog.dart  # "Your Next Task to Tackle!"
assets/fonts/                    # PlusJakartaSans-*.ttf + OFL.txt
test/
  models/  repositories/  services/  providers/  widgets/
```


---

## 4. Data Model

```dart
enum TaskStatus { todo, inProgress, done, messyCan }
enum TaskPriority { high, medium, low }

class Subtask { String id; String title; bool isDone; }

class Task {
  String id;              // UUID v4
  String title;
  String description;
  TaskStatus status;
  TaskPriority priority;
  String category;        // "Work", "Chores", "Personal", ... (user-extendable)
  List<String> labels;
  DateTime? dueDate;
  List<Subtask> subtasks;
  DateTime createdAt;
  DateTime updatedAt;     // added: needed for "merge" on import (newer wins)
}
```

- Immutable classes with `copyWith`, `toJson`, `fromJson`, `==`/`hashCode`.
- Enums serialized by `name` so backups stay readable and stable.
- Box layout: `tasks` box (key = task id, value = task JSON string), `settings` box (keys `appSettings` and `schemaVersion`).
- A `schemaVersion` field in the settings box and in backup files for future migrations.

---

## 5. Implementation Phases

Each phase ends with the app building and running on an Android emulator, plus its tests passing.

### Phase 0 — Project setup
- [x] Copy Plus Jakarta Sans (Regular, Medium, SemiBold, Bold + `OFL.txt`) from `/Users/bambook/Desktop/CarMobile/bma_mobile/assets/Plus_Jakarta_Sans/static/` into `assets/fonts/`.
- [x] `pubspec.yaml`: register the font block:
  ```yaml
  flutter:
    uses-material-design: true
    fonts:
      - family: PlusJakartaSans
        fonts:
          - asset: assets/fonts/PlusJakartaSans-Regular.ttf
          - asset: assets/fonts/PlusJakartaSans-Medium.ttf
            weight: 500
          - asset: assets/fonts/PlusJakartaSans-SemiBold.ttf
            weight: 600
          - asset: assets/fonts/PlusJakartaSans-Bold.ttf
            weight: 700
  ```
- [x] `pubspec.yaml`: add dependencies from §2.
- [x] Remove `lib/screens/nain_screen.dart`; create the folder structure.
- [x] `docs/SETUP.md` with step-by-step setup (deliverable #1).

### Phase 1 — Theme & app shell
- [x] `AppColors` with the README palette; light theme (off-white background) and dark theme (#1E1E24).
- [x] `ThemeData(fontFamily: 'PlusJakartaSans')`, pastel pink as primary, pastel blue as secondary, charcoal text/borders.
- [x] `HomeShell` with bottom `NavigationBar` and four placeholder tabs.

### Phase 2 — Data layer (deliverable #2)
- [x] `Task`, `Subtask`, enums, `AppSettings` with JSON round-trip (bad input → `FormatException`, used later by import validation).
- [x] `hive_setup.dart`: `Hive.initFlutter()`, open boxes before `runApp`; `main` records the schema version.
- [x] `TaskRepository`: `getAll` (skips corrupt entries), `getById`, `watch`, `upsert`, `upsertAll`, `delete`, `clear`, `replaceAll`. `SettingsRepository`: `load`/`save`, `ensureSchema`.
- [x] Providers: `hiveBoxesProvider` (overridden in `main`), repository providers, `clockProvider`, `tasksProvider` (`Notifier` with add/save/delete/moveTo/toggleSubtask, reloads on box changes), `settingsProvider`.
- [x] Tests: model JSON round-trip, repository CRUD against a temp Hive dir, notifier behavior via `ProviderContainer`.

### Phase 3 — Task editor & card
- [x] `TaskEditorScreen` (`ConsumerWidget`): title, description, status, priority, category (chips), labels (chips + suggestions from settings), due date picker, subtasks (add/check/remove). Save disabled without a title; delete with confirm; "Discard changes?" on back when edited.
- [x] Editor logic in `TaskEditorNotifier` (`providers/task_editor_provider.dart`, autoDispose family keyed by `TaskEditorArgs` — edit by id, or create with status/due-date presets for Calendar and Messy Can). New labels/categories are saved to settings.
- [x] `TaskCard`: title, priority indicator, category badge, subtask ratio (e.g. `2/5`), relative due date with "Overdue" for pending tasks.
- [x] Reusable stateless widgets in `ui/widgets/`: `PriorityIndicator`, `CategoryBadge`, `ChoiceChipGroup<T>`, `LabelInput`, `DueDateField`, `showConfirmDialog`; `AddItemField` (stateful only for its text controller).
- [x] Interim Board tab: list of board tasks (`boardTasksProvider`) + "New task" FAB, so the editor is reachable until Phase 4.
- [x] Tests: date helpers, editor notifier, `TaskCard` widget tests, editor create/discard/edit/delete widget tests (in-memory Hive via `test/helpers/`).

### Phase 4 — Kanban board
- [x] Horizontal `PageView` (`KanbanBoard`, neighbors peek in) with columns To Do · In Progress · Done; column header shows count, tap to jump.
- [x] Long-press drag a card onto another column → status change; auto-scroll to neighbor page when dragging near the edge (one flip per 700 ms).
- [x] Filter/sort bottom sheet (`FilterSortSheet`): multi-select labels, categories, priorities; sort by due date / priority / created date (asc/desc). Active filters shown as removable chips (`ActiveFilterChips`). Filter state is session-only (`boardFilterProvider`).
- [x] **Random Idea Picker** app-bar action: random task from To Do + In Progress (respecting active filters) → `showRandomPickDialog` "Your Next Task to Tackle!" with *Open*, *Start (move to In Progress)*, *Pick again* (never the same task twice in a row).
- [x] Tests: `BoardFilter` match/sort as pure functions, `pickRandom` with seeded `Random`, board providers, board widget tests (columns, drag, filter chips, random dialog).

### Phase 5 — Calendar
- [ ] `table_calendar` week/month toggle with dot markers on days that have tasks.
- [ ] Agenda list for the selected day (tasks whose `dueDate` falls on that day), tap to edit, checkbox to mark done.
- [ ] Quick-add bar at the bottom: type title → Enter creates a To Do task with `dueDate = selectedDay`.
- [ ] Tests: "tasks for day" selector (timezone/day-boundary cases).

### Phase 6 — Messy Can
- [ ] Fast entry field at top (title only, optional note); list/grid of ideas.
- [ ] Edit inline or in editor; swipe to delete with *Undo* snackbar.
- [ ] **Promote**: pick target status/priority/due date → status changes from `messyCan` to board status.
- [ ] **Randomizer** button → same dialog style, actions *Promote*, *Edit*, *Draw again*.
- [ ] Tests: promote flow, randomizer on empty/one-item lists.

### Phase 7 — Backup: export & import
- [ ] Backup JSON format:
  ```json
  { "app": "flutter_application_3_11", "schemaVersion": 1,
    "exportedAt": "...", "settings": { ... }, "tasks": [ ... ] }
  ```
- [ ] CSV export: one row per task; `labels` joined with `|`, `subtasks` as an embedded JSON string column.
- [ ] Export screen: choose JSON or CSV → write to app documents dir → *Share* via `share_plus`.
- [ ] Import screen: paste text area **or** file picker (`.json`, `.csv`) → parse + validate → preview ("12 tasks, 3 new, 9 existing") → choose:
  - **Restore**: clear and replace everything.
  - **Merge**: upsert by `id`, keep the newer `updatedAt` on conflict.
- [ ] Clear error messages for malformed input; never write partially on failure.
- [ ] Tests: JSON and CSV round-trip, merge conflict rules, invalid input.

### Phase 8 — Polish & release prep
- [ ] Empty states for every screen; loading/error states from `AsyncValue`.
- [ ] Dark mode toggle in settings; respect system setting by default.
- [ ] Accessibility: contrast check of pastel colors against charcoal text, semantic labels on icon buttons, large-text layout check.
- [ ] Android: app name, launcher icon, `minSdk` check for plugins, release build (`flutter build apk --release`).
- [ ] `flutter analyze` clean, all tests green.

---

## 6. Testing Strategy

- **Unit**: models, filter/sort/random logic (pure functions in providers or `core/utils`), backup service parsing and merging.
- **Repository**: Hive in a temp directory (`Hive.init(tempDir)`), no Flutter binding needed.
- **Provider**: `ProviderContainer` with overridden repository (in-memory fake).
- **Widget**: task card, filter sheet, quick-add bar, random dialog.
- Manual pass on an Android emulator at the end of every phase.

---

## 7. Risks & Open Questions

1. **Font (resolved)**: the README asks for Montserrat from `bma_mobile/assets/fonts/`, which does not exist; `bma_mobile/assets/` only has Plus Jakarta Sans. Decision: use **Plus Jakarta Sans** (SIL OFL, license copied to `assets/fonts/OFL.txt`). The README still says Montserrat — update it if it should match.
2. **Hive vs. SQLite**: Hive (CE) is chosen for simplicity. If complex queries become necessary later (e.g. full-text search), switch to `sqflite`/`drift` behind the same `TaskRepository` interface.
3. **Categories/labels management**: README lists defaults (Work, Chores, Personal). Plan: defaults seeded on first run, user can add more; stored in settings and included in backups.
4. **Drag-and-drop on small screens**: if dragging across pages feels clumsy, add a "Move to…" action on the card as a fallback.

---

## 8. Definition of Done

- All four features from the README work offline on an Android emulator/device.
- Data survives app restarts; export → wipe → import restores identical data.
- Code split into `data/` (models, db, repositories, services), `providers/`, and `ui/`.
- `docs/SETUP.md` explains setup, fonts, and dependencies.
- `flutter analyze` shows no issues; tests pass.
