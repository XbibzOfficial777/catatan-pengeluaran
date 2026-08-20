import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_models.dart';

class ReminderStorage {
  static const _key = 'reminder_schedules_v1';

  Future<List<ReminderSchedule>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null || raw.isEmpty) return <ReminderSchedule>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <ReminderSchedule>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ReminderSchedule.fromJson)
          .toList();
    } catch (_) {
      return <ReminderSchedule>[];
    }
  }

  Future<void> save(List<ReminderSchedule> reminders) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode(reminders.map((item) => item.toJson()).toList()),
    );
  }
}

class ReminderService {
  ReminderService._();
  static final instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      settings: const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (_) {},
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> syncAll(List<ReminderSchedule> reminders) async {
    await initialize();
    await _plugin.cancelAll();
    for (final reminder in reminders.where((item) => item.enabled)) {
      await schedule(reminder);
    }
  }

  Future<void> schedule(ReminderSchedule reminder) async {
    await initialize();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'catatbibz_reminders',
        'Pengingat CatatBibz',
        channelDescription:
            'Pengingat pembayaran, makan, ngopi, dan agenda pribadi.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    if (reminder.frequency == ReminderFrequency.daily) {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: _nextDaily(reminder.hour, reminder.minute),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'reminder:${reminder.id}',
      );
      return;
    }

    for (final weekday in reminder.weekdays.toSet()) {
      await _plugin.zonedSchedule(
        id: _notificationId(reminder.id, weekday),
        title: reminder.title,
        body: reminder.body,
        scheduledDate: _nextWeekday(weekday, reminder.hour, reminder.minute),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'reminder:${reminder.id}:$weekday',
      );
    }
  }

  Future<void> cancel(ReminderSchedule reminder) async {
    await initialize();
    await _plugin.cancel(id: reminder.id);
    for (final weekday in reminder.weekdays.toSet()) {
      await _plugin.cancel(id: _notificationId(reminder.id, weekday));
    }
  }

  int _notificationId(int reminderId, int weekday) => reminderId * 10 + weekday;

  tz.TZDateTime _nextDaily(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var date = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!date.isAfter(now)) date = date.add(const Duration(days: 1));
    return date;
  }

  tz.TZDateTime _nextWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var date = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (date.weekday != weekday || !date.isAfter(now)) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }
}
