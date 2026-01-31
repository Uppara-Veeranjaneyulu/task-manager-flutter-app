import 'package:flutter/material.dart';
import '../../core/services/notification_settings_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool enabled = false;
  bool dailyReminder = false;
  TimeOfDay reminderTime = const TimeOfDay(hour: 9, minute: 0);

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final data = await NotificationSettingsService.getSettings();

    setState(() {
      enabled = data['enabled'] ?? false;
      dailyReminder = data['dailyReminder'] ?? false;

      final time = data['reminderTime'] ?? '09:00';
      final parts = time.split(':');
      reminderTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );

      loading = false;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminderTime,
    );

    if (picked != null) {
      setState(() => reminderTime = picked);
    }
  }

  Future<void> _save() async {
    await NotificationSettingsService.updateSettings(
      enabled: enabled,
      dailyReminder: dailyReminder,
      reminderTime:
          "${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Notification settings saved")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text("Enable Notifications"),
              value: enabled,
              onChanged: (v) => setState(() => enabled = v),
            ),

            SwitchListTile(
              title: const Text("Daily Reminder"),
              value: dailyReminder,
              onChanged: enabled
                  ? (v) => setState(() => dailyReminder = v)
                  : null,
            ),

            ListTile(
              title: const Text("Reminder Time"),
              subtitle: Text(reminderTime.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: enabled && dailyReminder ? _pickTime : null,
            ),

            const Spacer(),

            ElevatedButton(onPressed: _save, child: const Text("Save")),
          ],
        ),
      ),
    );
  }
}
