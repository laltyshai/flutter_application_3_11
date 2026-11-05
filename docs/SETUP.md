# Setup

Step-by-step setup for the local-first To-Do & Task Tracker. See [PLAN.md](PLAN.md) for the overall plan.

## 1. Requirements

- Flutter 3.47+ (Dart SDK `^3.13.4`, see `pubspec.yaml`)
- Android Studio with an Android SDK and an emulator (or a USB-connected Android device)

Check with:

```bash
flutter doctor
```

## 2. Font (Plus Jakarta Sans)

The font files are already in `assets/fonts/`. They were copied from
`/Users/bambook/Desktop/CarMobile/bma_mobile/assets/Plus_Jakarta_Sans/static/`:

```
assets/fonts/
  PlusJakartaSans-Regular.ttf    (weight 400)
  PlusJakartaSans-Medium.ttf     (weight 500)
  PlusJakartaSans-SemiBold.ttf   (weight 600)
  PlusJakartaSans-Bold.ttf       (weight 700)
  OFL.txt                        (SIL Open Font License, must ship with the fonts)
```

To copy them again (for example on a fresh checkout without the files):

```bash
for w in Regular Medium SemiBold Bold; do cp "/Users/bambook/Desktop/CarMobile/bma_mobile/assets/Plus_Jakarta_Sans/static/PlusJakartaSans-$w.ttf" assets/fonts/; done
```

They are registered in `pubspec.yaml` as the family `PlusJakartaSans`:

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

The app theme sets it as the default font for the whole `MaterialApp` with
`ThemeData(fontFamily: 'PlusJakartaSans')` (see `lib/core/theme/app_theme.dart`).

## 3. Dependencies

| Package | Used for |
|---|---|
| `flutter_riverpod` | State management |
| `hive_ce`, `hive_ce_flutter` | Local database (no backend) |
| `uuid` | Task and subtask ids |
| `table_calendar` | Calendar day-by-day view |
| `intl` | Date formatting |
| `path_provider` | Where export files are written |
| `share_plus` | Sharing backups via the Android Share sheet |
| `file_picker` | Picking a backup file to import |
| `csv` | CSV export/import |

Install them:

```bash
flutter pub get
```

## 4. Run

Start an emulator (or plug in a device), then:

```bash
flutter run
```

## 5. Check

```bash
flutter analyze
```

```bash
flutter test
```
