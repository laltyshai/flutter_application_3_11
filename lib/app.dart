import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'ui/shell/home_shell.dart';

class TaskTrackerApp extends ConsumerWidget {
  const TaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Saved choice from Settings → Theme (System by default).
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp(
      title: 'Task Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const HomeShell(),
    );
  }
}
