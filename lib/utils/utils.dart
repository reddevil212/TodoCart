import 'package:intl/intl.dart';
import 'package:todocart/models/repeat_rule.dart';

String setGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) {
    return 'Good Morning';
  } else if (hour < 17) {
    return 'Good Afternoon';
  } else {
    return 'Good Evening';
  }
}

String normalizeTaskInput(String input) {
  return input
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('tommorow', 'tomorrow')
      .replaceAll('minues', 'minutes');
}

int partOfDayToHour(String period) {
  switch (period.toLowerCase()) {
    case 'morning':
      return 9;
    case 'afternoon':
      return 14;
    case 'evening':
      return 18;
    case 'night':
      return 21;
    default:
      return 9;
  }
}

int? weekdayFromText(String value) {
  const map = {
    'monday': DateTime.monday,
    'mon': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'tue': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'wed': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'thu': DateTime.thursday,
    'friday': DateTime.friday,
    'fri': DateTime.friday,
    'saturday': DateTime.saturday,
    'sat': DateTime.saturday,
    'sunday': DateTime.sunday,
    'sun': DateTime.sunday,
  };

  return map[value.toLowerCase()];
}

DateTime combineDateAndTime(DateTime date, int hour, int minute) {
  return DateTime(date.year, date.month, date.day, hour, minute);
}

DateTime nextWeekday(DateTime from, int weekday, {bool strictlyNext = false}) {
  var diff = weekday - from.weekday;
  if (diff < 0 || (strictlyNext && diff == 0)) {
    diff += 7;
  }

  return DateTime(from.year, from.month, from.day).add(Duration(days: diff));
}

DateTime parseClockTime(String hourText, String minuteText, String? period) {
  var hour = int.parse(hourText);
  final minute = int.parse(minuteText);

  if (period != null) {
    final lowerPeriod = period.toLowerCase();
    if (lowerPeriod == 'pm' && hour < 12) {
      hour += 12;
    }
    if (lowerPeriod == 'am' && hour == 12) {
      hour = 0;
    }
  }

  return DateTime(0, 1, 1, hour, minute);
}

DateTime nextTimeFromNow(DateTime now, int hour, int minute) {
  final today = DateTime(now.year, now.month, now.day, hour, minute);
  if (today.isAfter(now)) {
    return today;
  }
  return today.add(const Duration(days: 1));
}

String formatDueAt(DateTime? dueAt) {
  if (dueAt == null) {
    return 'No schedule set';
  }
  return DateFormat('dd MMM yyyy, hh:mm a').format(dueAt);
}

String formatRepeatRule(RepeatRule repeatRule) {
  final timeFormat = DateFormat('hh:mm a');

  switch (repeatRule.kind) {
    case RepeatKind.none:
      return 'One-time reminder';
    case RepeatKind.interval:
      final value = repeatRule.intervalMinutes ?? 0;
      return 'Repeats every $value minutes';
    case RepeatKind.daily:
      final hour = repeatRule.hour ?? 9;
      final minute = repeatRule.minute ?? 0;
      final time = timeFormat.format(DateTime(0, 1, 1, hour, minute));
      return 'Repeats daily at $time';
    case RepeatKind.weekly:
      final weekday = repeatRule.weekdays.isEmpty
          ? DateTime.monday
          : repeatRule.weekdays.first;
      final hour = repeatRule.hour ?? 9;
      final minute = repeatRule.minute ?? 0;
      final day = _weekdayLabel(weekday);
      final time = timeFormat.format(DateTime(0, 1, 1, hour, minute));
      return 'Repeats every $day at $time';
  }
}

String _weekdayLabel(int weekday) {
  const names = {
    DateTime.monday: 'Monday',
    DateTime.tuesday: 'Tuesday',
    DateTime.wednesday: 'Wednesday',
    DateTime.thursday: 'Thursday',
    DateTime.friday: 'Friday',
    DateTime.saturday: 'Saturday',
    DateTime.sunday: 'Sunday',
  };

  return names[weekday] ?? 'Monday';
}
