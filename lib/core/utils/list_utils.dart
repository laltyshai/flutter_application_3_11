/// Deals [items] into at most [maxRows] rows, column by column, so a grid
/// reads top-to-bottom then left-to-right: `[a, b, c, d, e]` with 2 rows →
/// `[[a, c, e], [b, d]]`. Fewer items than rows gives one row per item.
List<List<T>> splitIntoRows<T>(List<T> items, int maxRows) {
  assert(maxRows > 0, 'maxRows must be positive');
  final rowCount = items.length < maxRows ? items.length : maxRows;
  return [
    for (var r = 0; r < rowCount; r++)
      [for (var i = r; i < items.length; i += rowCount) items[i]],
  ];
}
