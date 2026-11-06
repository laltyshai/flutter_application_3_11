import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/random_picker.dart';
import '../data/models/task.dart';

/// Random source; overridden with a seeded [Random] in tests.
final randomProvider = Provider<Random>((ref) => Random());

/// Picks a random task from [candidates] (board picker, Messy Can draw).
class RandomTaskPicker {
  RandomTaskPicker(this.candidates, this._random);

  final List<Task> candidates;
  final Random _random;

  /// A random candidate, avoiding [excludeId] when another one exists.
  Task? pick({String? excludeId}) => pickRandom(
    candidates,
    _random,
    exclude: excludeId == null ? null : (t) => t.id == excludeId,
  );
}
