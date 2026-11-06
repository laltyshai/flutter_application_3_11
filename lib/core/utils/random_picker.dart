import 'dart:math';

/// Picks a random item from [items], or `null` when there is nothing to pick.
///
/// When [exclude] matches an item and other items exist, that item is skipped,
/// so "Pick again" never shows the same thing twice in a row.
T? pickRandom<T>(List<T> items, Random random, {bool Function(T)? exclude}) {
  if (items.isEmpty) return null;
  final pool = exclude == null
      ? items
      : [
          for (final item in items)
            if (!exclude(item)) item,
        ];
  final source = pool.isEmpty ? items : pool;
  return source[random.nextInt(source.length)];
}
