import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  // ── Init ──────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    tz.initializeTimeZones();
    // ✅ CRITICAL: set to IST — without this tz.local = UTC
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _notifications.initialize(
      const InitializationSettings(android: androidSettings),
    );
  }

  // ── Permission helpers ────────────────────────────────────────────────────

  /// Returns true if the app can schedule exact alarms (Android 12+).
  static Future<bool> canScheduleExactAlarms() async {
    return await _android?.canScheduleExactNotifications() ?? true;
  }

  /// Opens Settings → Alarms & reminders so the user can grant the permission.
  static Future<void> requestExactAlarmsPermission() async {
    await _android?.requestExactAlarmsPermission();
  }

  /// Request notification display permission (Android 13+).
  static Future<void> requestNotificationPermission() async {
    await _android?.requestNotificationsPermission();
  }

  // ── Test now ──────────────────────────────────────────────────────────────
  static Future<void> testNotification() async {
    await _notifications.show(
      999,
      'Test Notification',
      'If you see this, notifications work ✅',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Instant test notification',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
    );
  }

  // ── Test in N seconds ────────────────────────────────────────────────────
  static Future<void> testNotificationAfterSeconds(int seconds) async {
    final scheduled =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
    await _notifications.zonedSchedule(
      9999,
      'Test Notification',
      'This appeared after $seconds seconds 🔔',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Delayed test notification',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Daily reminder ────────────────────────────────────────────────────────

  /// Returns false if SCHEDULE_EXACT_ALARM permission not granted (Android 12+).
  /// Caller should call [requestExactAlarmsPermission] first.
  static Future<bool> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    // Check exact alarm permission
    final canSchedule = await canScheduleExactAlarms();
    if (!canSchedule) {
      return false; // caller must request permission
    }

    await _notifications.zonedSchedule(
      1001,
      '📋 Daily Task Reminder',
      "Don't forget to check your tasks for today!",
      _nextInstance(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          channelDescription: 'Daily task reminder',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
    return true;
  }

  static Future<void> cancelDailyReminder() async {
    await _notifications.cancel(1001);
  }

  // ── One-off task notification ─────────────────────────────────────────────
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Reminders for specific tasks',
          importance: Importance.max,
          priority: Priority.max,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  static tz.TZDateTime _nextInstance(int hour, int minute) {
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
}
