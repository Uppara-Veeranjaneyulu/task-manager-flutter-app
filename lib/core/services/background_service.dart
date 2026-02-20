import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart';
import 'email_service.dart';

const String taskSendEmail = "taskSendEmail";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("🔧 [BackgroundService] Executing task: $task");

    if (task == taskSendEmail) {
      if (inputData != null) {
        final toEmail = inputData['toEmail'] as String;
        final subject = inputData['subject'] as String;
        final body = inputData['body'] as String;

        debugPrint("📧 [BackgroundService] Sending email to $toEmail...");

        try {
          await EmailService.sendEmail(
            toEmail: toEmail,
            subject: subject,
            body: body,
          );
          debugPrint("✅ [BackgroundService] Email sent successfully!");
        } catch (e) {
          debugPrint("❌ [BackgroundService] Failed to send email: $e");
          return Future.value(false); // Retry
        }
      }
    }

    return Future.value(true);
  });
}

class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode, // TRUE for testing (instant execution)
    );
    debugPrint("🔧 [BackgroundService] Initialized!");
  }

  static Future<void> scheduleEmailTask({
    required int id,
    required String toEmail,
    required String subject,
    required String body,
    required Duration initialDelay,
  }) async {
    debugPrint("🔧 [BackgroundService] Scheduling email task (ID: $id) in ${initialDelay.inMinutes} mins");

    await Workmanager().registerOneOffTask(
      "email_task_$id",
      taskSendEmail,
      initialDelay: initialDelay,
      inputData: {
        'toEmail': toEmail,
        'subject': subject,
        'body': body,
      },
      constraints: Constraints(
        networkType: NetworkType.connected, // Needs internet
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  static Future<void> cancelEmailTask(int id) async {
    debugPrint("🔧 [BackgroundService] Cancelling email task (ID: $id)");
    await Workmanager().cancelByUniqueName("email_task_$id");
  }
}
