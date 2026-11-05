import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

@immutable
class Subtask {
  const Subtask({required this.id, required this.title, this.isDone = false});

  /// New subtask with a fresh UUID.
  factory Subtask.create(String title) =>
      Subtask(id: const Uuid().v4(), title: title);

  factory Subtask.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    if (id is! String || id.isEmpty || title is! String) {
      throw FormatException('Invalid subtask: $json');
    }
    return Subtask(id: id, title: title, isDone: json['isDone'] == true);
  }

  final String id;
  final String title;
  final bool isDone;

  Subtask copyWith({String? title, bool? isDone}) => Subtask(
    id: id,
    title: title ?? this.title,
    isDone: isDone ?? this.isDone,
  );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'isDone': isDone};

  @override
  bool operator ==(Object other) =>
      other is Subtask &&
      other.id == id &&
      other.title == title &&
      other.isDone == isDone;

  @override
  int get hashCode => Object.hash(id, title, isDone);

  @override
  String toString() => 'Subtask($id, $title, done: $isDone)';
}
