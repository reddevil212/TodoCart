import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:todocart/models/repeat_rule.dart';
import 'package:todocart/models/task.dart';

enum NotificationKind { immediate, oneTime, interval, daily, weekly }

class NotificationRequest {
  final int id;
  final String title;
  final String body;
  final NotificationKind kind;
  final DateTime? scheduledAt;
  final Duration? interval;
  final int? weekday;
  final int? hour;
  final int? minute;

  const NotificationRequest({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    this.scheduledAt,
    this.interval,
    this.weekday,
    this.hour,
    this.minute,
  });
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  AndroidScheduleMode _scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;

  static const int _maxNotificationId = 2147483647;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: settings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();

    final canExact = await androidPlugin?.canScheduleExactNotifications();
    if (canExact == false) {
      final granted = await androidPlugin?.requestExactAlarmsPermission();
      _scheduleMode = granted == true
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
    }

    const channel = AndroidNotificationChannel(
      'general_channel',
      'General Notifications',
      description: 'Notifications for scheduled tasks and reminders',
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
  }

  Future<void> schedule(NotificationRequest request) async {
    final details = _notificationDetails();
    final notificationId = _toNotificationId(request.id);

    switch (request.kind) {
      case NotificationKind.immediate:
        await _plugin.show(
          id: notificationId,
          title: request.title,
          body: request.body,
          notificationDetails: details,
        );
        return;

      case NotificationKind.oneTime:
        if (request.scheduledAt == null) return;
        await _plugin.zonedSchedule(
          id: notificationId,
          title: request.title,
          body: request.body,
          scheduledDate: tz.TZDateTime.from(request.scheduledAt!, tz.local),
          notificationDetails: details,
          androidScheduleMode: _scheduleMode,
        );
        return;

      case NotificationKind.interval:
        if (request.interval == null) return;
        await _plugin.periodicallyShowWithDuration(
          id: notificationId,
          title: request.title,
          body: request.body,
          repeatDurationInterval: request.interval!,
          notificationDetails: details,
          androidScheduleMode: _scheduleMode,
        );
        return;

      case NotificationKind.daily:
        if (request.hour == null || request.minute == null) return;
        final scheduled = _nextDailyTime(request.hour!, request.minute!);
        await _plugin.zonedSchedule(
          id: notificationId,
          title: request.title,
          body: request.body,
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: _scheduleMode,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        return;

      case NotificationKind.weekly:
        if (request.weekday == null ||
            request.hour == null ||
            request.minute == null) {
          return;
        }
        final scheduled = _nextWeekdayTime(
          request.weekday!,
          request.hour!,
          request.minute!,
        );
        await _plugin.zonedSchedule(
          id: notificationId,
          title: request.title,
          body: request.body,
          scheduledDate: scheduled,
          notificationDetails: details,
          androidScheduleMode: _scheduleMode,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
        return;
    }
  }

  Future<void> scheduleTaskReminder(Task task) async {
    final dueAt = task.dueAt;

    if (!task.repeatRule.isRepeating) {
      if (dueAt == null) {
        return;
      }

      await schedule(
        NotificationRequest(
          id: task.id,
          title: 'Task Reminder',
          body: task.title,
          kind: NotificationKind.oneTime,
          scheduledAt: dueAt,
        ),
      );
      return;
    }

    switch (task.repeatRule.kind) {
      case RepeatKind.interval:
        await schedule(
          NotificationRequest(
            id: task.id,
            title: 'Task Reminder',
            body: task.title,
            kind: NotificationKind.interval,
            interval: Duration(minutes: task.repeatRule.intervalMinutes ?? 60),
          ),
        );
        return;
      case RepeatKind.daily:
        await schedule(
          NotificationRequest(
            id: task.id,
            title: 'Task Reminder',
            body: task.title,
            kind: NotificationKind.daily,
            hour: task.repeatRule.hour,
            minute: task.repeatRule.minute,
          ),
        );
        return;
      case RepeatKind.weekly:
        final weekdays = task.repeatRule.weekdays;
        if (weekdays.isEmpty) return;

        await schedule(
          NotificationRequest(
            id: task.id,
            title: 'Task Reminder',
            body: task.title,
            kind: NotificationKind.weekly,
            weekday: weekdays.first,
            hour: task.repeatRule.hour,
            minute: task.repeatRule.minute,
          ),
        );
        return;
      case RepeatKind.none:
        return;
    }
  }

  Future<void> cancelById(int id) => _plugin.cancel(id: _toNotificationId(id));

  int _toNotificationId(int id) {
    var normalized = id % _maxNotificationId;
    if (normalized < 0) {
      normalized += _maxNotificationId;
    }
    if (normalized == 0) {
      normalized = 1;
    }
    return normalized;
  }

  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'general_channel',
      'General Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    return const NotificationDetails(android: androidDetails);
  }

  tz.TZDateTime _nextDailyTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextWeekdayTime(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
