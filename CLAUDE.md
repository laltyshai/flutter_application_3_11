# CLAUDE.md — Task Tracker (flutter_application_3_11)

Operating guide for Claude Code in this repo. Rules adapted from
`/Users/bambook/Desktop/CarMobile/CLAUDE.md` (+ its `bma_mobile/docs/`), keeping only
what applies to a local-first app with no backend. Plan: `docs/PLAN.md`. Setup: `docs/SETUP.md`.

## Response protocol (required)

Reply in a formal, minimal structure. Use only the sections that apply, in this order, as
short bullet points — no filler prose:

- **Goal** — what the user wants, in one line.
- **Catches** — constraints, hidden assumptions, things that will bite.
- **Problems** — what is actually wrong / root cause.
- **Suggestions** — options considered, with trade-offs.
- **Solution** — the chosen approach, one line.
- **Fixed** — what changed and how (file:line), verification result.

Skip a section if it has nothing substantive. Do not pad.

### Explanations (code-teacher and any "explain" answer)
- Start with a short **Terms** list defining every technical word used, in plain language,
  each tied to real code in this repo. Keep `docs/GLOSSARY.md` in sync: add new terms there.
- Explain with the app's own things (tasks, the editor, the board), not invented objects.
  No metaphors with made-up roles (e.g. "coat", "ticket", "hook"); if a comparison is truly
  needed, say explicitly what each part maps to in the code.
- Show real code from this repo and trace what happens step by step.

## Project facts

- Local-first To-Do / Task Tracker, Android first. No backend; data lives in Hive (`hive_ce`).
- App is at the repo root. Package name: `flutter_application_3_11`
  (imports: `package:flutter_application_3_11/...`).
- Flutter 3.47, Dart SDK `^3.13.4`. **State: Riverpod (`flutter_riverpod` 3.x) — not `provider`.**
- Font: Plus Jakarta Sans (family `PlusJakartaSans`), not the README's Montserrat.

## Architecture (layer-first, see `docs/PLAN.md` §3)

Keep this folder structure. Don't move to CarMobile's feature-first layout.

```
lib/
├── main.dart          # Hive init + ProviderScope (composition root)
├── app.dart           # MaterialApp + theme
├── core/              # theme/, utils/ — imports nothing from data/, providers/, ui/
├── data/              # models/, db/, repositories/, services/ — no Flutter widgets, no providers
├── providers/         # Riverpod notifiers + derived providers
└── ui/                # shell/, board/, calendar/, messy_can/, backup/, task/, widgets/
```

### Dependency direction (keep it this way)
- `core/` → nothing in the app. `data/` → `core/` only. `providers/` → `data/`, `core/`.
  `ui/` → everything above.
- Notifiers, repositories and services never import a `ui/` file.
- One screen folder never imports another screen folder's private widgets; shared UI goes in
  `ui/widgets/`.

## Conventions

### State (Riverpod)
- `NotifierProvider<XNotifier, XState>` with immutable state (models with `copyWith`, `==`).
  No codegen.
- UI: `ConsumerWidget` / `ConsumerStatefulWidget`. `ref.watch(provider)` in `build`;
  mutate via `ref.read(provider.notifier).method()` in callbacks.
- Don't add `package:provider`, `setState`-based global state, or another state library.
  `setState` is fine for purely local widget state (e.g. the selected tab).

### Widgets: reusable, stateless, no logic
- Always try to make widgets reusable and stateless (`StatelessWidget` / `ConsumerWidget`).
  Use a `StatefulWidget` only for state that is purely visual and local (animation, text
  controller, focus, selected tab) — and say why in a one-line comment.
- Widgets only render data and forward user actions. Filtering, sorting, random picking,
  validation, date math and persistence live in notifiers, `core/utils/` pure functions or
  `data/services/` — never inside `build` or an `onPressed` body.
- Reusable widgets take plain data and callbacks (`Task task`, `VoidCallback onTap`,
  `ValueChanged<TaskStatus> onMove`), not providers, so they work on any screen and in tests.
  Screens (`ConsumerWidget`) are the place that reads providers and wires callbacks.
- If a widget's `build` grows past one screen or mixes concerns, split it into smaller widgets.

### SOLID — single responsibility & open/closed
- **Single responsibility:** one reason to change per class/file. A model holds data, a
  repository stores it, a service converts it (e.g. JSON/CSV), a notifier coordinates it, a
  widget draws it. When a class does two of these, split it.
- **Open/closed:** extend by adding, not by editing existing code. Prefer enums with fields
  (`TaskStatus.label`), maps/lists of options, and small strategy objects or functions (e.g.
  one sort comparator per sort mode, one exporter per format) over growing `if`/`switch`
  chains. A new status, sort mode or export format should mostly be a new entry, not edits
  across many files.
- Depend on what a class needs, passed in through the constructor or a provider, so it can be
  swapped in tests.

### Repositories & DI (Riverpod is the container)
- Reach repositories/services through providers, never `XRepository()` at a call site.
  In notifiers use a getter: `TaskRepository get _repo => ref.read(taskRepositoryProvider);`
- Keep constructors injectable (`TaskRepository(Box<String> box)`) so tests pass fakes or
  temp Hive boxes. Time comes from `clockProvider`, never `DateTime.now()` inside logic.

### Styling
- Colors from `core/theme/app_colors.dart`, theme from `core/theme/app_theme.dart`; prefer
  `Theme.of(context).colorScheme`. No raw hex outside `core/theme/`.

### Reuse first
Before adding a widget, provider or helper, search `ui/widgets/`, `core/utils/` and
`providers/` (e.g. `EmptyState` for empty screens).

### Code style
- Typed, null-safe code; avoid gratuitous `dynamic`. Comments in English.
- No `print`; use `debugPrint` for diagnostics.
- Match surrounding style; minimal, targeted diffs.

## Commands

```bash
flutter pub get
flutter analyze          # must be fully clean (infos count) before done
flutter test             # must pass before done
dart format lib test     # keep formatted
flutter run              # needs an emulator/device
flutter build apk --release
```

- Tests: unit tests for pure logic and models; repository tests on a temp Hive dir
  (`test/helpers/test_hive.dart`); notifier tests via `ProviderContainer`; widget tests for UI.
  New test files mirror the `lib/` path. Scroll widgets into view (`tester.ensureVisible`)
  before tapping — the test screen is 800x600.
- Don't claim a UI flow is tested unless a widget test covers it; otherwise run the screen.
- Lint baseline is `package:flutter_lints/flutter.yaml` with no rule-level ignores. Don't add
  any without asking.

## Working agreement

- **Never commit or push.** The user commits; suggest commit splits only if asked.
- Never hardcode or echo secrets.
