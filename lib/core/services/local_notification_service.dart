import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// 🔔 INITIALIZE (CALL ON APP START)
  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);
  }

  // ============================================================
  // ✅ INSTANT TEST (CONFIRMS NOTIFICATIONS WORK)
  // ============================================================
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
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  // ============================================================
  // ✅ SHORT DELAY TEST (BEST FOR DEBUGGING)
  // ============================================================
  static Future<void> testNotificationAfterSeconds(int seconds) async {
  await Future.delayed(Duration(seconds: seconds));

  await _notifications.show(
    9999,
    'Test Notification',
    'This should appear after $seconds seconds 🔔',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Immediate test notification',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}


  // ============================================================
  // 🔔 DAILY REMINDER (BEST POSSIBLE LOCAL VERSION)
  // ============================================================
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _notifications.zonedSchedule(
      1001,
      'Daily Reminder',
      'Don’t forget to check your tasks 📋',
      _nextInstance(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          channelDescription: 'Daily task reminder',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ============================================================
  // ❌ CANCEL DAILY REMINDER
  // ============================================================
  static Future<void> cancelDailyReminder() async {
    await _notifications.cancel(1001);
  }

  // ============================================================
  // ⏰ CALCULATE NEXT TIME
  // ============================================================
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
