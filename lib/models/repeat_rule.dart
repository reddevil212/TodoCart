enum RepeatKind { none, interval, daily, weekly }

class RepeatRule {
  final RepeatKind kind;
  final int? intervalMinutes;
  final int? hour;
  final int? minute;
  final List<int> weekdays;

  const RepeatRule._({
    required this.kind,
    this.intervalMinutes,
    this.hour,
    this.minute,
    this.weekdays = const [],
  });

  const RepeatRule.none() : this._(kind: RepeatKind.none);

  const RepeatRule.interval(int minutes)
    : this._(kind: RepeatKind.interval, intervalMinutes: minutes);

  const RepeatRule.daily({required int hour, required int minute})
    : this._(kind: RepeatKind.daily, hour: hour, minute: minute);

  const RepeatRule.weekly({
    required List<int> weekdays,
    required int hour,
    required int minute,
  }) : this._(
         kind: RepeatKind.weekly,
         weekdays: weekdays,
         hour: hour,
         minute: minute,
       );

  bool get isRepeating => kind != RepeatKind.none;

  Map<String, dynamic> toMap() {
    return {
      'kind': kind.name,
      'intervalMinutes': intervalMinutes,
      'hour': hour,
      'minute': minute,
      'weekdays': weekdays,
    };
  }

  static RepeatRule fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return const RepeatRule.none();
    }

    final kindName = (map['kind'] as String? ?? RepeatKind.none.name)
        .toLowerCase();
    final intervalMinutes = (map['intervalMinutes'] as num?)?.toInt();
    final hour = (map['hour'] as num?)?.toInt();
    final minute = (map['minute'] as num?)?.toInt();
    final weekdays =
        (map['weekdays'] as List?)
            ?.whereType<num>()
            .map((e) => e.toInt())
            .toList() ??
        const <int>[];

    switch (kindName) {
      case 'interval':
        if (intervalMinutes == null || intervalMinutes <= 0) {
          return const RepeatRule.none();
        }
        return RepeatRule.interval(intervalMinutes);
      case 'daily':
        if (hour == null || minute == null) {
          return const RepeatRule.none();
        }
        return RepeatRule.daily(hour: hour, minute: minute);
      case 'weekly':
        if (hour == null || minute == null || weekdays.isEmpty) {
          return const RepeatRule.none();
        }
        return RepeatRule.weekly(
          weekdays: weekdays,
          hour: hour,
          minute: minute,
        );
      default:
        return const RepeatRule.none();
    }
  }
}
