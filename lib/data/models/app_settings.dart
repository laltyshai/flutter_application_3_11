import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

/// How the Kanban board lays out its status lists.
enum BoardLayout {
  /// Each status is a horizontal row of cards (stacked vertically).
  rows('Rows'),

  /// Each status is a swipeable vertical column.
  columns('Columns');

  const BoardLayout(this.label);
  final String label;

  /// Parses a stored name; unknown values fall back to [rows].
  static BoardLayout fromName(Object? name) =>
      values.firstWhere((l) => l.name == name, orElse: () => rows);
}

@immutable
class AppSettings {
  AppSettings({
    this.themeMode = ThemeMode.system,
    this.boardLayout = BoardLayout.rows,
    List<String> categories = defaultCategories,
    List<String> labels = const [],
  }) : categories = List.unmodifiable(categories),
       labels = List.unmodifiable(labels);

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    themeMode: ThemeMode.values.firstWhere(
      (m) => m.name == json['themeMode'],
      orElse: () => ThemeMode.system,
    ),
    boardLayout: BoardLayout.fromName(json['boardLayout']),
    categories: _strings(json['categories']) ?? defaultCategories,
    labels: _strings(json['labels']) ?? const [],
  );

  /// Seeded on first run; the user can add more.
  static const defaultCategories = ['Work', 'Chores', 'Personal', 'Study'];

  final ThemeMode themeMode;
  final BoardLayout boardLayout;
  final List<String> categories;
  final List<String> labels;

  AppSettings copyWith({
    ThemeMode? themeMode,
    BoardLayout? boardLayout,
    List<String>? categories,
    List<String>? labels,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    boardLayout: boardLayout ?? this.boardLayout,
    categories: categories ?? this.categories,
    labels: labels ?? this.labels,
  );

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'boardLayout': boardLayout.name,
    'categories': categories,
    'labels': labels,
  };

  static List<String>? _strings(Object? value) => value is List
      ? [
          for (final v in value)
            if (v is String) v,
        ]
      : null;

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.boardLayout == boardLayout &&
      listEquals(other.categories, categories) &&
      listEquals(other.labels, labels);

  @override
  int get hashCode => Object.hash(
    themeMode,
    boardLayout,
    Object.hashAll(categories),
    Object.hashAll(labels),
  );
}
