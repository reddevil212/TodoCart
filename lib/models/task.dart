import 'package:todocart/models/repeat_rule.dart';

class Task {
  int id;
  String title;
  bool isCompleted = false;
  DateTime creationTime = DateTime.now();
  String? sourceText;
  DateTime? dueAt;
  RepeatRule repeatRule;

  Task({
    required this.id,
    required this.title,
    this.sourceText,
    this.dueAt,
    this.repeatRule = const RepeatRule.none(),
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'creationTime': creationTime.toIso8601String(),
      'sourceText': sourceText,
      'dueAt': dueAt?.toIso8601String(),
      'repeatRule': repeatRule.toMap(),
    };
  }

  static Task fromMap(Map<dynamic, dynamic> map) {
    final task = Task(
      id: (map['id'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      title: map['title'] as String? ?? '',
      sourceText: map['sourceText'] as String?,
      dueAt: map['dueAt'] == null
          ? null
          : DateTime.tryParse(map['dueAt'] as String)?.toLocal(),
      repeatRule: RepeatRule.fromMap(
        map['repeatRule'] as Map<dynamic, dynamic>?,
      ),
    );

    task.isCompleted = map['isCompleted'] as bool? ?? false;
    final creation = DateTime.tryParse(map['creationTime'] as String? ?? '');
    if (creation != null) {
      task.creationTime = creation.toLocal();
    }
    return task;
  }
}
