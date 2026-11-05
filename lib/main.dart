import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Hive setup is added here in Phase 2 (data layer), before runApp.
  runApp(const ProviderScope(child: TaskTrackerApp()));
}
