import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/hive_setup.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/task_repository.dart';

/// Opened Hive boxes. Must be overridden in `main` (after [HiveSetup.init])
/// and in tests.
final hiveBoxesProvider = Provider<HiveBoxes>(
  (ref) => throw UnimplementedError(
    'hiveBoxesProvider must be overridden with opened boxes',
  ),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(hiveBoxesProvider).tasks),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(hiveBoxesProvider).settings),
);

/// Current time; overridden in tests for deterministic timestamps.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
