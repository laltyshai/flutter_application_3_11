import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'ui/shell/home_shell.dart';

class TaskTrackerApp extends StatelessWidget {
  const TaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Follows the system setting until the settings toggle lands (Phase 8).
      themeMode: ThemeMode.system,
      home: const HomeShell(),
    );
  }
}
