import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/db/hive_setup.dart';
import 'data/repositories/settings_repository.dart';
import 'providers/repository_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final boxes = await HiveSetup.init();
  await SettingsRepository(boxes.settings).ensureSchema();

  runApp(
    ProviderScope(
      overrides: [hiveBoxesProvider.overrideWithValue(boxes)],
      child: const TaskTrackerApp(),
    ),
  );
}
