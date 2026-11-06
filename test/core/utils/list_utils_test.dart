import 'package:flutter_application_3_11/core/utils/list_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deals items column by column into at most maxRows rows', () {
    expect(splitIntoRows(['a', 'b', 'c', 'd', 'e'], 2), [
      ['a', 'c', 'e'],
      ['b', 'd'],
    ]);
    expect(splitIntoRows([1, 2, 3, 4], 2), [
      [1, 3],
      [2, 4],
    ]);
  });

  test('fewer items than rows gives one row per item; empty gives none', () {
    expect(splitIntoRows(['a'], 2), [
      ['a'],
    ]);
    expect(splitIntoRows(<int>[], 2), isEmpty);
    expect(splitIntoRows([1, 2, 3], 1), [
      [1, 2, 3],
    ]);
  });
}
