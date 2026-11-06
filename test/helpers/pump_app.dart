import 'package:flutter/material.dart';
import 'package:flutter_application_3_11/core/theme/app_theme.dart';
import 'package:flutter_application_3_11/data/db/hive_setup.dart';
import 'package:flutter_application_3_11/providers/repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed "now" for widget tests: Thu 5 Nov 2026, 09:00.
final testNow = DateTime(2026, 11, 5, 9);

extension PumpApp on WidgetTester {
  /// Pumps [child] inside Riverpod (with [boxes] and a fixed clock) and the
  /// app theme. Returns the container so tests can read providers.
  Future<ProviderContainer> pumpApp(
    Widget child, {
    required HiveBoxes boxes,
    DateTime? now,
  }) async {
    final container = ProviderContainer(
      overrides: [
        hiveBoxesProvider.overrideWithValue(boxes),
        clockProvider.overrideWithValue(() => now ?? testNow),
      ],
    );
    addTearDown(container.dispose);
    await pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light(), home: child),
      ),
    );
    await pumpAndSettle();
    return container;
  }
}
