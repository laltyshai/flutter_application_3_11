import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

@immutable
class AppSettings {
  AppSettings({
    this.themeMode = ThemeMode.system,
    List<String> categories = defaultCategories,
    List<String> labels = const [],
  }) : categories = List.unmodifiable(categories),
       labels = List.unmodifiable(labels);

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    themeMode: ThemeMode.values.firstWhere(
      (m) => m.name == json['themeMode'],
      orElse: () => ThemeMode.system,
    ),
    categories: _strings(json['categories']) ?? defaultCategories,
    labels: _strings(json['labels']) ?? const [],
  );

  /// Seeded on first run; the user can add more.
  static const defaultCategories = ['Work', 'Chores', 'Personal', 'Study'];

  final ThemeMode themeMode;
  final List<String> categories;
  final List<String> labels;

  AppSettings copyWith({
    ThemeMode? themeMode,
    List<String>? categories,
    List<String>? labels,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    categories: categories ?? this.categories,
    labels: labels ?? this.labels,
  );

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
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
      listEquals(other.categories, categories) &&
      listEquals(other.labels, labels);

  @override
  int get hashCode => Object.hash(
    themeMode,
    Object.hashAll(categories),
    Object.hashAll(labels),
  );
}
