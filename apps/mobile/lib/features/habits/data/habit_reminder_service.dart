import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../../../core/utils/web_notif.dart';
import 'models/habit_model.dart';

class HabitReminderService {
  static final HabitReminderService _instance = HabitReminderService._();
  factory HabitReminderService() => _instance;
  HabitReminderService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'habit_reminders',
      'Habit Reminders',
      channelDescription: 'Daily reminders for your habit goals',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Android 13+ requires a runtime POST_NOTIFICATIONS grant
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // Fires an immediate notification — no scheduling, no exact-alarm permission needed.
  // On web uses the browser Notification API; on mobile uses flutter_local_notifications.
  Future<void> sendTestNow() async {
    if (kIsWeb) {
      await showBrowserNotification(
        '🔔 Habit Reminder Test',
        'Notifications are working! Your daily reminders are all set.',
      );
      return;
    }
    await initialize();
    await _plugin.show(
      9999,
      '🔔 Habit Reminder Test',
      'Notifications are working! Your daily reminders are all set.',
      _details,
    );
  }

  // Schedule a daily reminder for each habit that has a reminderTime set.
  // Cancels all previous habit reminders first so stale ones don't accumulate.
  Future<void> scheduleHabitReminders(List<Habit> habits) async {
    if (kIsWeb) return; // browser notifications are one-shot only, no daily scheduling
    await initialize();
    for (int i = 1000; i < 2000; i++) {
      await _plugin.cancel(i);
    }

    final habitsWithReminders = habits
        .where((h) => h.reminderTime != null && h.reminderTime!.isNotEmpty)
        .toList();

    for (int i = 0; i < habitsWithReminders.length; i++) {
      final habit = habitsWithReminders[i];
      final parts = habit.reminderTime!.split(':');
      if (parts.length != 2) continue;
      final hour   = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      await _scheduleDaily(
        id: 1000 + i,
        title: '${habit.emoji} Time for ${habit.name}!',
        body: _reminderBody(habit),
        hour: hour,
        minute: minute,
      );
    }
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  String _reminderBody(Habit habit) {
    if (habit.currentStreak > 0) {
      return 'Keep your ${habit.currentStreak}-day streak alive! '
          'Goal: ${habit.targetValue} ${habit.unit}';
    }
    return 'Daily goal: ${habit.targetValue} ${habit.unit}. You\'ve got this!';
  }

  Future<void> cancelAll() async {
    await initialize();
    for (int i = 1000; i < 2000; i++) {
      await _plugin.cancel(i);
    }
  }
}
