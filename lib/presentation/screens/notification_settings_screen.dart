import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/background_service.dart';
import '../../core/services/email_service.dart';
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
  bool _sendingTestEmail = false;

  String get uid => FirebaseAuth.instance.currentUser!.uid;
  String get userEmail => FirebaseAuth.instance.currentUser!.email ?? '';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadSettings();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 5));

      final data = doc.data()?['notifications'];
      if (data != null && mounted) {
        final timeStr = (data['reminderTime'] as String?) ?? '09:00';
        final parts = timeStr.split(':');
        setState(() {
          _dailyReminder = data['dailyReminder'] ?? false;
          _time = TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 9,
            minute: int.tryParse(parts[1]) ?? 0,
          );
        });
      }
    } catch (_) {
      // use defaults silently
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Directly sends the daily reminder email NOW (bypasses WorkManager).
  Future<void> _sendDailyEmailNow() async {
    setState(() => _sendingTestEmail = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .where('isCompleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final tasks = snap.docs.map((d) => d.data()).toList();
      final taskLines = tasks.isEmpty
          ? '🎉 No pending tasks — you\'re all caught up!'
          : tasks.map((t) {
              final title = t['title'] ?? '';
              final desc = (t['description'] as String?) ?? '';
              return desc.isNotEmpty ? '• $title\n  $desc' : '• $title';
            }).join('\n');

      await EmailService.sendEmail(
        toEmail: userEmail,
        subject:
            '📋 Daily Reminder — ${tasks.length} pending task${tasks.length != 1 ? "s" : ""}',
        body: 'Good day! Here are your pending tasks:\n\n$taskLines\n\n---\nSent by Task Manager App.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Email sent to $userEmail'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Email failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingTestEmail = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      if (_dailyReminder) {
        // Always schedule email via WorkManager (no special permission needed)
        await BackgroundService.scheduleDailyEmailReminder(
          uid: uid,
          toEmail: userEmail,
          userName: FirebaseAuth.instance.currentUser?.displayName ?? 'there',
          time: _time,
        );

        // Try local notification popup (needs exact alarm on Android 12+)
        final canExact = await LocalNotificationService.canScheduleExactAlarms();
        if (canExact) {
          await LocalNotificationService.scheduleDailyReminder(
            hour: _time.hour,
            minute: _time.minute,
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    'Email reminder set! Grant "Alarms & reminders" for popup too.'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.orange.shade700,
                action: SnackBarAction(
                  label: 'Fix',
                  textColor: Colors.white,
                  onPressed: LocalNotificationService.requestExactAlarmsPermission,
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } else {
        await LocalNotificationService.cancelDailyReminder();
        await BackgroundService.cancelDailyEmailReminder();
      }

      // Firestore fire-and-forget
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'notifications.dailyReminder': _dailyReminder,
        'notifications.reminderTime':
            '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
      });

      if (mounted) {
        final msg = _dailyReminder
            ? 'Daily reminder scheduled!'
            : 'Daily reminder disabled.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text(msg),
            ]),
            backgroundColor: _dailyReminder ? Colors.green : Colors.grey,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Battery banner
          FutureBuilder<List<bool>>(
            future: Future.wait([
              NotificationHealthService.hasNotificationPermission(),
              NotificationHealthService.isBatteryOptimisationDisabled(),
            ]),
            builder: (ctx, snap) {
              if (!snap.hasData) return const SizedBox();
              if (snap.data![0] && snap.data![1]) return const SizedBox();
              return Card(
                color: Colors.orange.shade100,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.warning_amber,
                            color: Colors.orange),
                        title: const Text('Reminders may be delayed',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text(
                            'Disable battery optimisation for reliable delivery'),
                        trailing: TextButton(
                          onPressed: NotificationHealthService.openBatterySettings,
                          child: const Text('Fix'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Daily reminder toggle
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_active),
              title: const Text('Daily Reminder'),
              subtitle:
                  const Text('Get a popup + email every day at the set time'),
              value: _dailyReminder,
              onChanged: (v) => setState(() => _dailyReminder = v),
            ),
          ),

          const SizedBox(height: 8),

          // Time picker
          Card(
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Reminder Time'),
              subtitle: Text(_time.format(context)),
              trailing: const Icon(Icons.chevron_right),
              enabled: _dailyReminder,
              onTap: _dailyReminder ? _pickTime : null,
            ),
          ),

          const SizedBox(height: 24),

          // Save button
          FilledButton.icon(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save),
            label: const Text('Save Settings'),
            onPressed: _saving ? null : _save,
          ),

          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),

          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('Test',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          const SizedBox(height: 8),

          // Test popup notification
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.notifications),
                  label: const Text('Test Popup'),
                  onPressed: () async {
                    await LocalNotificationService.testNotification();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Test notification sent!'),
                            behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.timer),
                  label: const Text('Popup in 10s'),
                  onPressed: () async {
                    await LocalNotificationService
                        .testNotificationAfterSeconds(10);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Notification in 10 seconds!'),
                            behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Test email button — sends email IMMEDIATELY, no WorkManager
          OutlinedButton.icon(
            icon: _sendingTestEmail
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.email_outlined),
            label: Text(_sendingTestEmail
                ? 'Sending email…'
                : 'Send Daily Summary Email Now'),
            onPressed: _sendingTestEmail ? null : _sendDailyEmailNow,
          ),

          const SizedBox(height: 4),
          Text(
            'Sends to: $userEmail',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
