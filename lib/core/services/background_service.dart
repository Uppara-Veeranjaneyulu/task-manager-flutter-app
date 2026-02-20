import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'email_service.dart';

const String taskSendEmail = "taskSendEmail";
const String taskSendDailyEmail = "taskSendDailyEmail";

// ─────────────────────────────────────────────────────────────────────────────
// Background entry point — same isolate pattern as working task reminders.
// IMPORTANT: No Firebase/Firestore here — all data is passed via inputData.
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('[WorkManager] task=$task data=$inputData');

    if (inputData == null) return true;

    // Both task types use identical email logic — keeps it simple and reliable
    if (task == taskSendEmail || task == taskSendDailyEmail) {
      try {
        await EmailService.sendEmail(
          toEmail: inputData['toEmail'] as String,
          subject: inputData['subject'] as String,
          body:    inputData['body']    as String,
        );
        debugPrint('[WorkManager] ✅ Email sent → ${inputData['toEmail']}');
      } catch (e) {
        debugPrint('[WorkManager] ❌ Email failed: $e');
        return false; // WorkManager will retry
      }

      // For daily reminders, reschedule for the same time tomorrow
      if (task == taskSendDailyEmail) {
        final uid    = inputData['uid']    as String? ?? '';
        final hour   = inputData['hour']   as int;
        final minute = inputData['minute'] as int;
        final toEmail = inputData['toEmail'] as String;
        final name    = inputData['name']   as String? ?? 'there';

        await Workmanager().registerOneOffTask(
          'daily_email_reminder',
          taskSendDailyEmail,
          initialDelay: _delayUntilNext(hour, minute),
          inputData: {
            'uid':     uid,
            'toEmail': toEmail,
            'name':    name,
            'hour':    hour,
            'minute':  minute,
            'subject': inputData['subject'] as String,
            'body':    inputData['body']    as String,
          },
          existingWorkPolicy: ExistingWorkPolicy.replace,
        );
        debugPrint('[WorkManager] 🔁 Rescheduled for tomorrow ${hour.toString().padLeft(2,'0')}:${minute.toString().padLeft(2,'0')}');
      }
    }

    return true;
  });
}

Duration _delayUntilNext(int hour, int minute) {
  // DateTime.now() is already in the device's local timezone (IST).
  // No manual UTC↔IST conversion needed — that was causing the 1111-min bug.
  final now = DateTime.now();
  var target = DateTime(now.year, now.month, now.day, hour, minute);
  if (!target.isAfter(now)) {
    // Time already passed today → schedule for tomorrow
    target = target.add(const Duration(days: 1));
  }
  return target.difference(now);
}

// ─────────────────────────────────────────────────────────────────────────────
class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode, // logs tasks in debug builds
    );
  }

  // ── One-off task reminder ──────────────────────────────────────────────────
  static Future<void> scheduleEmailTask({
    required int id,
    required String toEmail,
    required String subject,
    required String body,
    required Duration initialDelay,
  }) async {
    await Workmanager().registerOneOffTask(
      'email_task_$id',
      taskSendEmail,
      initialDelay: initialDelay,
      inputData: {'toEmail': toEmail, 'subject': subject, 'body': body},
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  static Future<void> cancelEmailTask(int id) async {
    await Workmanager().cancelByUniqueName('email_task_$id');
  }

  // ── Daily email reminder ───────────────────────────────────────────────────
  /// Schedules a daily email at [time] IST.
  /// All data is baked into inputData — NO Firebase in background isolate.
  static Future<void> scheduleDailyEmailReminder({
    required String uid,
    required String toEmail,
    required String userName,
    required TimeOfDay time,
  }) async {
    await Workmanager().cancelByUniqueName('daily_email_reminder');

    final hour   = time.hour;
    final minute = time.minute;
    final delay  = _delayUntilNext(hour, minute);
    final hh     = hour.toString().padLeft(2, '0');
    final mm     = minute.toString().padLeft(2, '0');
    final subject = '📋 Daily Task Reminder ($hh:$mm)';
    final body = '''Hi $userName,

This is your daily task reminder at $hh:$mm.

Open the Task Manager app to see your pending tasks and stay on top of your day!

---
Task Manager App
''';

    debugPrint('[WorkManager] Scheduling daily email in ${delay.inMinutes} min → $toEmail');

    await Workmanager().registerOneOffTask(
      'daily_email_reminder',
      taskSendDailyEmail,
      initialDelay: delay,
      inputData: {
        'uid':     uid,
        'toEmail': toEmail,
        'name':    userName,
        'hour':    hour,
        'minute':  minute,
        'subject': subject,
        'body':    body,
      },
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  static Future<void> cancelDailyEmailReminder() async {
    await Workmanager().cancelByUniqueName('daily_email_reminder');
  }
}
