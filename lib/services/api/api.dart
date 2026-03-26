import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:todocart/models/repeat_rule.dart';
import 'package:todocart/models/task_structure.dart';
import 'package:todocart/utils/utils.dart';

class ParseTaskResponse {
  final TaskStructure structure;
  final bool usedFallback;
  final String assistantMessage;

  const ParseTaskResponse({
    required this.structure,
    required this.usedFallback,
    required this.assistantMessage,
  });
}

Future<TaskStructure> getSturcture(
  String input, {
  String? openRouterApiKey,
}) async {
  final response = await parseTaskCommand(
    input,
    openRouterApiKey: openRouterApiKey,
  );
  return response.structure;
}

Future<ParseTaskResponse> parseTaskCommand(
  String input, {
  String? openRouterApiKey,
  String model = 'openai/gpt-4o-mini',
}) async {
  final normalized = normalizeTaskInput(input);
  final key = (openRouterApiKey ?? dotenv.env['OPENROUTER_API_KEY'] ?? '')
      .trim();

  if (key.isEmpty) {
    debugPrint('[ParseTaskCommand] No API key found, using local fallback.');
    final fallback = _localFallbackGetStructure(normalized);
    return ParseTaskResponse(
      structure: fallback,
      usedFallback: true,
      assistantMessage: _fallbackAssistantMessage(
        fallback,
        apiStatusCode: null,
      ),
    );
  }

  int? apiStatusCode;

  try {
    debugPrint('[ParseTaskCommand] Calling OpenRouter API...');
    final body = {
      'model': model,
      'messages': [
        {
          'role': 'system',
          'content':
              'Extract reminder/task data from user text. Respond with JSON only. '
              'Schema: {"title":string,"dueAtIso":string|null,'
              '"repeat":{"kind":"none|interval|daily|weekly",'
              '"intervalMinutes":int|null,"hour":int|null,"minute":int|null,'
              '"weekdays":[int]}}. '
              'Weekdays use ISO 1-7 for Mon-Sun. If unknown time, use nulls.',
        },
        {'role': 'user', 'content': normalized},
      ],
      'temperature': 0.1,
    };

    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      apiStatusCode = response.statusCode;
      debugPrint('[ParseTaskCommand] API error: ${response.statusCode}');
      throw Exception('OpenRouter status: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      debugPrint('[ParseTaskCommand] API returned no choices.');
      throw Exception('No choices from OpenRouter');
    }

    final first = choices.first as Map<String, dynamic>;
    final message = first['message'] as Map<String, dynamic>?;
    final content = message?['content'];
    final contentText = _contentToText(content);
    final parsedMap =
        jsonDecode(_extractJson(contentText)) as Map<String, dynamic>;

    final structure = _structureFromMap(
      rawInput: normalized,
      mapped: parsedMap,
      fallbackTitle: _extractTitle(normalized),
    );
    debugPrint('[ParseTaskCommand] API call successful, structure parsed.');

    return ParseTaskResponse(
      structure: structure,
      usedFallback: false,
      assistantMessage: 'Voice command processed',
    );
  } catch (e) {
    debugPrint('[ParseTaskCommand] Falling back to local parser: $e');
    final fallback = _localFallbackGetStructure(normalized);
    return ParseTaskResponse(
      structure: fallback,
      usedFallback: true,
      assistantMessage: _fallbackAssistantMessage(
        fallback,
        apiStatusCode: apiStatusCode,
      ),
    );
  }
}

String _fallbackAssistantMessage(
  TaskStructure structure, {
  required int? apiStatusCode,
}) {
  final title = structure.title.trim();
  if (title.isNotEmpty) {
    if (apiStatusCode == 402) {
      return 'OpenRouter credits unavailable. Task added with local parser.';
    }
    return 'Task added from voice command.';
  }

  return 'Turn on Internet for voice command, or you can add a task in the app';
}

TaskStructure _structureFromMap({
  required String rawInput,
  required Map<String, dynamic> mapped,
  required String fallbackTitle,
}) {
  final title = (mapped['title'] as String?)?.trim();
  final dueAtIso = mapped['dueAtIso'] as String?;
  final repeat = mapped['repeat'] as Map<String, dynamic>?;

  DateTime? dueAt;
  if (dueAtIso != null && dueAtIso.trim().isNotEmpty) {
    dueAt = DateTime.tryParse(dueAtIso.trim())?.toLocal();
  }

  final repeatRule = _repeatFromMap(repeat);

  return TaskStructure(
    rawInput: rawInput,
    title: (title == null || title.isEmpty) ? fallbackTitle : title,
    dueAt: dueAt,
    repeatRule: repeatRule,
  );
}

RepeatRule _repeatFromMap(Map<String, dynamic>? repeat) {
  if (repeat == null) {
    return const RepeatRule.none();
  }

  final kind = (repeat['kind'] as String? ?? 'none').toLowerCase();
  final intervalMinutes = repeat['intervalMinutes'] as int?;
  final hour = repeat['hour'] as int?;
  final minute = repeat['minute'] as int?;
  final weekdaysRaw = (repeat['weekdays'] as List<dynamic>? ?? const [])
      .whereType<num>()
      .map((e) => e.toInt())
      .where((e) => e >= 1 && e <= 7)
      .toList();

  switch (kind) {
    case 'interval':
      if (intervalMinutes != null && intervalMinutes > 0) {
        return RepeatRule.interval(intervalMinutes);
      }
      return const RepeatRule.none();
    case 'daily':
      if (hour != null && minute != null) {
        return RepeatRule.daily(hour: hour, minute: minute);
      }
      return const RepeatRule.none();
    case 'weekly':
      if (hour != null && minute != null && weekdaysRaw.isNotEmpty) {
        return RepeatRule.weekly(
          weekdays: weekdaysRaw,
          hour: hour,
          minute: minute,
        );
      }
      return const RepeatRule.none();
    default:
      return const RepeatRule.none();
  }
}

String _contentToText(dynamic content) {
  if (content is String) {
    return content;
  }

  if (content is List) {
    return content
        .whereType<Map<String, dynamic>>()
        .map((item) => (item['text'] as String?) ?? '')
        .join('\n')
        .trim();
  }

  return '';
}

String _extractJson(String content) {
  final trimmed = content.trim();
  final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(trimmed);
  if (fenced != null) {
    return fenced.group(1)!.trim();
  }

  final start = trimmed.indexOf('{');
  final end = trimmed.lastIndexOf('}');
  if (start >= 0 && end > start) {
    return trimmed.substring(start, end + 1);
  }

  return trimmed;
}

TaskStructure _localFallbackGetStructure(String input) {
  final normalized = normalizeTaskInput(input);
  final lower = normalized.toLowerCase();
  final now = DateTime.now();
  final fixedDate = _extractSpecificDate(lower, now);
  final hasToday = RegExp(r'\btoday\b').hasMatch(lower);
  final hasTomorrow = RegExp(r'\btomorrow\b').hasMatch(lower);

  final everyInterval = RegExp(
    r'every\s+(\d+)\s*(minute|minutes|hour|hours)',
  ).firstMatch(lower);
  if (everyInterval != null) {
    final value = int.parse(everyInterval.group(1)!);
    final unit = everyInterval.group(2)!;
    final minutes = unit.startsWith('hour') ? value * 60 : value;

    return TaskStructure(
      rawInput: input,
      title: _extractTitle(normalized),
      dueAt: now.add(Duration(minutes: minutes)),
      repeatRule: RepeatRule.interval(minutes),
    );
  }

  final afterDuration = RegExp(
    r'after\s+(\d+)\s*(minute|minutes|hour|hours)',
  ).firstMatch(lower);
  if (afterDuration != null) {
    final value = int.parse(afterDuration.group(1)!);
    final unit = afterDuration.group(2)!;
    final duration = unit.startsWith('hour')
        ? Duration(hours: value)
        : Duration(minutes: value);

    return TaskStructure(
      rawInput: input,
      title: _extractTitle(normalized),
      dueAt: now.add(duration),
    );
  }

  final everyWeekday = RegExp(
    r'(?:on\s+)?every\s+([a-z]+)(?:\s+(morning|afternoon|evening|night))?',
  ).firstMatch(lower);
  if (everyWeekday != null) {
    final weekdayText = everyWeekday.group(1)!;
    final weekday = weekdayFromText(weekdayText);

    if (weekday != null) {
      final period = everyWeekday.group(2);
      final hour = period == null ? 9 : partOfDayToHour(period);
      final dueDate = combineDateAndTime(nextWeekday(now, weekday), hour, 0);

      return TaskStructure(
        rawInput: input,
        title: _extractTitle(normalized),
        dueAt: dueDate,
        repeatRule: RepeatRule.weekly(
          weekdays: [weekday],
          hour: hour,
          minute: 0,
        ),
      );
    }
  }

  final everyPartOfDay = RegExp(
    r'every\s+(morning|afternoon|evening|night)',
  ).firstMatch(lower);
  if (everyPartOfDay != null) {
    final period = everyPartOfDay.group(1)!;
    final hour = partOfDayToHour(period);

    return TaskStructure(
      rawInput: input,
      title: _extractTitle(normalized),
      dueAt: nextTimeFromNow(now, hour, 0),
      repeatRule: RepeatRule.daily(hour: hour, minute: 0),
    );
  }

  final tomorrowPartOfDay = RegExp(
    r'tomorrow(?:\s+(morning|afternoon|evening|night))?',
  ).firstMatch(lower);
  if (tomorrowPartOfDay != null) {
    final period = tomorrowPartOfDay.group(1);
    final hour = period == null ? 9 : partOfDayToHour(period);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    return TaskStructure(
      rawInput: input,
      title: _extractTitle(normalized),
      dueAt: combineDateAndTime(tomorrow, hour, 0),
    );
  }

  if (fixedDate != null) {
    final timeParts = _extractTimeParts(lower);
    if (timeParts != null) {
      final resolved = _resolveDueAtFromTime(
        now: now,
        hourText: timeParts.hourText,
        minuteText: timeParts.minuteText,
        period: timeParts.period,
        fixedDate: fixedDate,
        allowAmbiguousNearest: false,
      );

      return TaskStructure(
        rawInput: input,
        title: _extractTitle(normalized),
        dueAt: resolved,
      );
    }

    return TaskStructure(
      rawInput: input,
      title: _extractTitle(normalized),
      dueAt: DateTime(fixedDate.year, fixedDate.month, fixedDate.day, 9),
    );
  }

  final nextWeekdayMatch = RegExp(
    r'next\s+([a-z]+)(?:\s+(morning|afternoon|evening|night))?',
  ).firstMatch(lower);
  if (nextWeekdayMatch != null) {
    final weekday = weekdayFromText(nextWeekdayMatch.group(1)!);
    if (weekday != null) {
      final period = nextWeekdayMatch.group(2);
      final hour = period == null ? 9 : partOfDayToHour(period);
      final nextDay = nextWeekday(now, weekday, strictlyNext: true);

      return TaskStructure(
        rawInput: input,
        title: _extractTitle(normalized),
        dueAt: combineDateAndTime(nextDay, hour, 0),
      );
    }
  }

  final explicitTime = _extractTimeParts(lower);
  if (explicitTime != null) {
    final baseDate = hasTomorrow
        ? DateTime(now.year, now.month, now.day + 1)
        : hasToday
        ? DateTime(now.year, now.month, now.day)
        : null;

    final dueAt = _resolveDueAtFromTime(
      now: now,
      hourText: explicitTime.hourText,
      minuteText: explicitTime.minuteText,
      period: explicitTime.period,
      fixedDate: baseDate,
      allowAmbiguousNearest: baseDate == null,
    );

    return TaskStructure(
      rawInput: input,
      title: _extractTitle(normalized),
      dueAt: dueAt,
    );
  }

  return TaskStructure(rawInput: input, title: _extractTitle(normalized));
}

String _extractTitle(String input) {
  var title = input;

  title = title.replaceFirst(
    RegExp(
      r'^(remind me to|remind me|have to|i have to|need to)\s*',
      caseSensitive: false,
    ),
    '',
  );

  title = title
      .replaceAll(
        RegExp(
          r'\b(after\s+\d+\s*(minute|minutes|hour|hours))\b',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(
        RegExp(
          r'\b(every\s+\d+\s*(minute|minutes|hour|hours))\b',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(
        RegExp(
          r'\b((on\s+)?every\s+[a-z]+(\s+(morning|afternoon|evening|night))?)\b',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(
        RegExp(
          r'\bevery\s+(morning|afternoon|evening|night)\b',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(
        RegExp(
          r'\btomorrow(\s+(morning|afternoon|evening|night))?\b',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(RegExp(r'\btoday\b', caseSensitive: false), '')
      .replaceAll(
        RegExp(
          r'\b(on\s+)?\d{1,2}(st|nd|rd|th)?\s+[a-z]+(\s+\d{4})?\b',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(
        RegExp(
          r'\bnext\s+[a-z]+(\s+(morning|afternoon|evening|night))?\b',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(
        RegExp(
          r'\b(on|at)\s*\d{1,2}(:\d{2})?\s*(am|pm)?\b',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (title.isEmpty) {
    return input;
  }

  return title;
}

DateTime? _extractSpecificDate(String lower, DateTime now) {
  final dayMonthYear = RegExp(
    r'\b(?:on\s+)?(\d{1,2})(st|nd|rd|th)?\s+([a-z]+)(?:\s+(\d{4}))?\b',
  ).firstMatch(lower);

  if (dayMonthYear != null) {
    final day = int.tryParse(dayMonthYear.group(1)!);
    final month = _monthFromText(dayMonthYear.group(3)!);
    final year = int.tryParse(dayMonthYear.group(4) ?? '') ?? now.year;

    if (day != null && month != null) {
      return DateTime(year, month, day);
    }
  }

  final slashDate = RegExp(
    r'\b(\d{1,2})/(\d{1,2})/(\d{4})\b',
  ).firstMatch(lower);
  if (slashDate != null) {
    final day = int.tryParse(slashDate.group(1)!);
    final month = int.tryParse(slashDate.group(2)!);
    final year = int.tryParse(slashDate.group(3)!);
    if (day != null && month != null && year != null) {
      return DateTime(year, month, day);
    }
  }

  return null;
}

_TimeParts? _extractTimeParts(String lower) {
  final withColon = RegExp(
    r'\b(?:at|on)\s*(\d{1,2}):(\d{2})\s*(am|pm)?\b',
  ).firstMatch(lower);
  if (withColon != null) {
    return _TimeParts(
      hourText: withColon.group(1)!,
      minuteText: withColon.group(2)!,
      period: withColon.group(3),
    );
  }

  final amPmHour = RegExp(
    r'\b(?:at|on)\s*(\d{1,2})\s*(am|pm)\b',
  ).firstMatch(lower);
  if (amPmHour != null) {
    return _TimeParts(
      hourText: amPmHour.group(1)!,
      minuteText: '00',
      period: amPmHour.group(2),
    );
  }

  return null;
}

DateTime _resolveDueAtFromTime({
  required DateTime now,
  required String hourText,
  required String minuteText,
  required String? period,
  required DateTime? fixedDate,
  required bool allowAmbiguousNearest,
}) {
  final parsedHour = int.parse(hourText);
  final minute = int.parse(minuteText);

  if (period != null) {
    final parsed = parseClockTime(hourText, minuteText, period);
    final base = fixedDate ?? DateTime(now.year, now.month, now.day);
    final candidate = DateTime(
      base.year,
      base.month,
      base.day,
      parsed.hour,
      parsed.minute,
    );
    if (fixedDate != null || candidate.isAfter(now)) {
      return candidate;
    }
    return candidate.add(const Duration(days: 1));
  }

  if (fixedDate != null) {
    final hour = parsedHour.clamp(0, 23);
    return DateTime(
      fixedDate.year,
      fixedDate.month,
      fixedDate.day,
      hour,
      minute,
    );
  }

  if (!allowAmbiguousNearest || parsedHour > 12) {
    return nextTimeFromNow(now, parsedHour.clamp(0, 23), minute);
  }

  final amCandidate = DateTime(
    now.year,
    now.month,
    now.day,
    parsedHour,
    minute,
  );
  final pmCandidate = DateTime(
    now.year,
    now.month,
    now.day,
    parsedHour + 12,
    minute,
  );

  final upcoming = <DateTime>[
    amCandidate.isAfter(now)
        ? amCandidate
        : amCandidate.add(const Duration(days: 1)),
    pmCandidate.isAfter(now)
        ? pmCandidate
        : pmCandidate.add(const Duration(days: 1)),
  ]..sort();

  return upcoming.first;
}

int? _monthFromText(String monthText) {
  const months = {
    'january': 1,
    'jan': 1,
    'february': 2,
    'feb': 2,
    'march': 3,
    'mar': 3,
    'april': 4,
    'apr': 4,
    'may': 5,
    'june': 6,
    'jun': 6,
    'july': 7,
    'jul': 7,
    'august': 8,
    'aug': 8,
    'september': 9,
    'sep': 9,
    'october': 10,
    'oct': 10,
    'november': 11,
    'nov': 11,
    'december': 12,
    'dec': 12,
  };

  return months[monthText.toLowerCase()];
}

class _TimeParts {
  final String hourText;
  final String minuteText;
  final String? period;

  const _TimeParts({
    required this.hourText,
    required this.minuteText,
    required this.period,
  });
}
