import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String get _uid => _auth.currentUser!.uid;

  static DocumentReference get _ref => _db.collection('users').doc(_uid);

  /// 🔔 Fetch notification settings
  static Future<Map<String, dynamic>> getSettings() async {
    final doc = await _ref.get();
    final data = doc.data() as Map<String, dynamic>;

    return data['notifications'] ??
        {'enabled': false, 'dailyReminder': false, 'reminderTime': '09:00'};
  }

  /// 💾 Save notification settings
  static Future<void> updateSettings({
    required bool enabled,
    required bool dailyReminder,
    required String reminderTime,
  }) async {
    await _ref.update({
      'notifications': {
        'enabled': enabled,
        'dailyReminder': dailyReminder,
        'reminderTime': reminderTime,
      },
    });
  }
}
