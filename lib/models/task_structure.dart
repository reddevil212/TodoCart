import 'package:todocart/models/repeat_rule.dart';

class TaskStructure {
  final String rawInput;
  final String title;
  final DateTime? dueAt;
  final RepeatRule repeatRule;

  const TaskStructure({
    required this.rawInput,
    required this.title,
    this.dueAt,
    this.repeatRule = const RepeatRule.none(),
  });
}
