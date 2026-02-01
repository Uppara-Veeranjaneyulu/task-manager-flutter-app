import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/local_notification_service.dart';

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
    _requestNotificationPermission(); // ✅ ONLY THIS
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
      _time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// ⏰ PICK TIME
  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text("Daily Reminder"),
            subtitle: const Text("Get reminded every day"),
            value: _dailyReminder,
            onChanged: (value) {
              setState(() => _dailyReminder = value);
            },
          ),

          ListTile(
            title: const Text("Reminder Time"),
            subtitle: Text(_time.format(context)),
            trailing: const Icon(Icons.access_time),
            enabled: _dailyReminder,
            onTap: _dailyReminder ? _pickTime : null,
          ),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const CircularProgressIndicator()
                : const Text("Save"),
          ),

          ElevatedButton(
            onPressed: () async {
              await LocalNotificationService.testNotification();
            },
            child: const Text("Test Notification NOW"),
          )

        ],
      ),
    );
  }
}
