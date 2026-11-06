import 'dart:math';

import 'package:flutter_application_3_11/core/utils/random_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty list gives null', () {
    expect(pickRandom<int>(const [], Random(1)), isNull);
  });

  test('single item is always picked, even when excluded', () {
    expect(pickRandom([7], Random(1)), 7);
    expect(pickRandom([7], Random(1), exclude: (x) => x == 7), 7);
  });

  test('same seed gives the same pick', () {
    final items = List.generate(20, (i) => i);
    expect(pickRandom(items, Random(42)), pickRandom(items, Random(42)));
  });

  test('excluded item is never picked when others exist', () {
    final random = Random(3);
    for (var i = 0; i < 50; i++) {
      expect(pickRandom([1, 2], random, exclude: (x) => x == 1), 2);
    }
  });

  test('every item can be picked', () {
    final random = Random(5);
    final seen = {
      for (var i = 0; i < 100; i++) pickRandom([1, 2, 3], random),
    };
    expect(seen, {1, 2, 3});
  });
}
