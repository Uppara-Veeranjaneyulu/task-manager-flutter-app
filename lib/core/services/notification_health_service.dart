import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationHealthService {
  /// 🔔 Notification permission
  static Future<bool> hasNotificationPermission() async {
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    }
    return true;
  }

  /// 🔋 Battery optimization (cannot reliably detect)
  static Future<bool> isBatteryOptimisationDisabled() async {
    return false; // assume NOT disabled
  }

  /// ⚙️ Open battery optimization settings
  static Future<void> openBatterySettings() async {
    if (!Platform.isAndroid) return;

    try {
      const intent = AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
      );
      await intent.launch();
    } catch (_) {
      const intent = AndroidIntent(
        action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
      );
      await intent.launch();
    }
  }
}
