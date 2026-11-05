# flutter_application_3_11

You are an expert Senior Flutter Developer. Build a complete, modular, and performant local-first To-Do and Task Tracker mobile application for Android.

Follow these strict requirements, folder structures, visual guidelines, and functional features.

---

### Visual Guidelines & Branding
- Platform Focus: Android primary target.
- Color Palette:
  * Primary Accent: Soft Pastel Pink (#F4C2C2 / #FFB7B2)
  * Secondary Accent: Soft Pastel Blue (#AEC6CF / #B3C5FF)
  * Backgrounds: Clean Off-White (#F8F9FA) with Dark Contrast (#1E1E24)
  * Text & Borders: Rich Black / Deep Charcoal (#1A1A1A) for clean contrast.
- Typography:
  * Font Family: Montserrat
  * Implementation: State clearly in pubspec.yaml to copy Montserrat fonts directly from `/Users/bambook/Desktop/CarMobile/bma_mobile/assets/fonts/` into the local `assets/fonts/` directory. Configure the MaterialApp fallback font to use Montserrat.

---

### Technical Architecture & Data Storage
- State Management: Riverpod (or Provider) with clean, maintainable separation of presentation and logic.
- Storage (No Backend): Local database using Hive or Isar/SQLite (e.g., `sqflite` or `hive_flutter`).
- Data Model:
  * `Task`: `id` (UUID), `title`, `description`, `status` (enum: Todo, In Progress, Done, Messy Can), `priority` (High, Medium, Low), `category/theme` (Work, Chores, Personal, etc.), `labels` (List<String>), `dueDate` (DateTime?), `subtasks` (List<Subtask>), `createdAt` (DateTime).

---

### Core Features & Views

#### 1. Mobile Kanban Board (GitHub Projects Style)
- Column-based drag-and-drop or horizontal swipe interface for status columns (e.g., To Do, In Progress, Done).
- Interactive Task Cards displaying title, priority indicator, category badge, and subtask completion ratio.
- GitHub-style Filtering & Sorting:
  * Filter by: Labels, Categories/Themes, Priority level.
  * Sort by: Due Date, Priority, Creation Date.
- **"Random Idea Picker" Button:** An action that picks a random pending task from the Kanban board and presents it as a focused modal ("Your Next Task to Tackle!").

#### 2. Calendar Day-by-Day View
- Daily agenda calendar view (e.g., table_calendar or custom daily timeline).
- Filter and view tasks scheduled for specific days.
- Quick inline task creation directly attached to the selected calendar date.

#### 3. Messy Can (Idea Sandbox & Random To-Do)
- A flexible dump screen for quick, unstructured ideas and brain dumps (unscheduled/unassigned tasks).
- Full CRUD operations: Create, Read, Update (edit or promote to Kanban task), Delete.
- **Randomizer Feature:** A dedicated button that draws a random entry from the "Messy Can" to spark immediate action.

#### 4. Backup & Data Export/Import
- Export: Serialize all tasks, categories, and settings into a JSON or CSV file stored locally or shareable via Android Share Intent.
- Import: A dedicated paste/file-picker view allowing users to paste JSON/CSV text or load a backup file to restore or merge app data.

---

### Deliverables Required
1. Step-by-step setup instructions (pubspec.yaml configuration for Montserrat font assets and dependencies).
2. Clean database initialization setup.
3. Complete, production-grade Flutter code cleanly split across models, services/repositories, providers, and UI screens/widgets.
