import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/local_notification_service.dart';
import '../../core/services/notification_health_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _dailyReminder = false;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool _loading = true;
  bool _saving = false;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _loadSettings();
  }

  /// 🔔 ANDROID 13+ PERMISSION
  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  /// 🔄 LOAD FROM FIRESTORE
  Future<void> _loadSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data()?['notifications'];

    if (data != null) {
      final timeStr = data['reminderTime'] ?? "09:00";
      final parts = timeStr.split(':');

      _dailyReminder = data['dailyReminder'] ?? false;
      _time = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    setState(() => _loading = false);
  }

  /// 💾 SAVE SETTINGS
  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'notifications.dailyReminder': _dailyReminder,
        'notifications.reminderTime':
            "${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}",
      });

      if (_dailyReminder) {
        await LocalNotificationService.scheduleDailyReminder(
          hour: _time.hour,
          minute: _time.minute,
        );
      } else {
        await LocalNotificationService.cancelDailyReminder();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Notification settings saved")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// ⏰ PICK TIME
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// ⚠️ STATUS BANNER
FutureBuilder<List<bool>>(
  future: Future.wait([
    NotificationHealthService.hasNotificationPermission(),
    NotificationHealthService.isBatteryOptimisationDisabled(),
  ]),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const SizedBox();

    final hasPermission = snapshot.data![0];
    final batteryOk = snapshot.data![1];

    if (hasPermission && batteryOk) return const SizedBox();

    return Card(
      color: Colors.orange.shade100,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: const Text("Reminders may be delayed"),
              subtitle: const Text(
                "Battery optimization can block notifications",
              ),
              trailing: TextButton(
                onPressed: () {
                  NotificationHealthService.openBatterySettings();
                },
                child: const Text("Fix"),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Steps to fix:\n"
              "1. Find this app\n"
              "2. Battery → No restrictions\n"
              "3. Allow background activity",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  },
),



          /// 🔔 TOGGLE
          SwitchListTile(
            title: const Text("Daily Reminder"),
            subtitle: const Text("Get reminded every day"),
            value: _dailyReminder,
            onChanged: (value) {
              setState(() => _dailyReminder = value);
            },
          ),

          /// ⏰ TIME PICKER
          ListTile(
            title: const Text("Reminder Time"),
            subtitle: Text(_time.format(context)),
            trailing: const Icon(Icons.access_time),
            enabled: _dailyReminder,
            onTap: _dailyReminder ? _pickTime : null,
          ),

          const SizedBox(height: 24),

          /// 💾 SAVE
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const CircularProgressIndicator()
                : const Text("Save"),
          ),

          const SizedBox(height: 12),

          /// 🧪 TEST NOW
          TextButton.icon(
            icon: const Icon(Icons.notifications_active),
            label: const Text("Test notification now"),
            onPressed: () async {
              await LocalNotificationService.testNotification();

            },
          ),

          TextButton.icon(
            icon: const Icon(Icons.timer),
            label: const Text("Test after 10 seconds"),
            onPressed: () async {
              await LocalNotificationService.testNotificationAfterSeconds(10);
            },
          ),
        ],
      ),
    );
  }
}
