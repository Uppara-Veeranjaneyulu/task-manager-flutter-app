import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/task_model.dart';
import '../../core/services/local_notification_service.dart';
import '../../core/services/background_service.dart';

class EditTaskScreen extends StatefulWidget {
  final TaskModel task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  late TextEditingController titleController;
  late TextEditingController descriptionController;

  DateTime? selectedDateTime;
  bool isStarred = false;
  String? selectedList; // ⚠️ nullable
  String selectedPriority = 'Medium';

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.task.title);
    descriptionController =
        TextEditingController(text: widget.task.description);

    selectedDateTime = widget.task.dueDateTime;
    isStarred = widget.task.isStarred;
    selectedList = widget.task.listName;
    selectedPriority = widget.task.priority;
  }

  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: selectedDateTime ?? DateTime.now(),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: selectedDateTime != null
          ? TimeOfDay.fromDateTime(selectedDateTime!)
          : TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> updateTask() async {
    // 🔔 NOTIFICATION LOGIC
    int? notificationId = widget.task.notificationId;

    // 1. Cancel old notification if it exists (Local + Background)
    if (notificationId != null) {
      await LocalNotificationService.cancelNotification(notificationId);
      await BackgroundService.cancelEmailTask(notificationId);
    }

    // 2. Schedule new notification if we have a due date
    if (selectedDateTime != null) {
      // Create new ID if none existed, or reuse (but simpler to just make new ID to avoid collisions is fine, 
      // but let's reuse or generate new. Generating new is safer for "unique" pending intents usually)
      notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final scheduledTime = selectedDateTime!.subtract(const Duration(minutes: 10));
      
      if (scheduledTime.isAfter(DateTime.now())) {
        await LocalNotificationService.scheduleNotification(
          id: notificationId,
          title: "Reminder: ${titleController.text}",
          body: "Your task is due in 10 minutes!",
          scheduledDate: scheduledTime,
        );

        // 📧 Schedule Real Email via Workmanager
        final delay = scheduledTime.difference(DateTime.now());
        if (delay.inSeconds > 0) {
           await BackgroundService.scheduleEmailTask(
            id: notificationId,
            toEmail: FirebaseAuth.instance.currentUser?.email ?? "unknown@user.com",
            subject: "Updated Reminder: ${titleController.text}",
            body: "Your task '${titleController.text}' is now due at $selectedDateTime.",
            initialDelay: delay,
          );
        }
      }
    } else {
      // If date cleared, ensure ID is nulled out in DB
      notificationId = null; 
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .doc(widget.task.id)
        .update({
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'dueDateTime': selectedDateTime,
      'isStarred': isStarred,
      'listName': selectedList ?? 'My Tasks',
      'priority': selectedPriority,
      'updatedAt': Timestamp.now(),
      'notificationId': notificationId,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit task"),
        actions: [
          IconButton(
            icon: Icon(
              isStarred ? Icons.star : Icons.star_border,
              color: isStarred ? Colors.amber : null,
            ),
            onPressed: () {
              setState(() => isStarred = !isStarred);
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: updateTask,
        child: const Icon(Icons.check),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: "Task title"),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: pickDateTime,
                ),
                if (selectedDateTime != null)
                  Text(
                    "${selectedDateTime!.day}/${selectedDateTime!.month} "
                    "${selectedDateTime!.hour.toString().padLeft(2, '0')}:"
                    "${selectedDateTime!.minute.toString().padLeft(2, '0')}",
                  ),
              ],
            ),

            const SizedBox(height: 12),

            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(hintText: "Description"),
              maxLines: 3,
            ),

            const SizedBox(height: 12),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: selectedPriority,
              decoration: const InputDecoration(labelText: "Priority"),
              items: ['Low', 'Medium', 'High']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (val) => setState(() => selectedPriority = val!),
            ),

            const SizedBox(height: 12),

            // ✅ SAFE LIST DROPDOWN
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('lists')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }

                final listNames = snapshot.data!.docs
                    .map((d) => d['name'] as String)
                    .toList();

                // 🔒 SAFETY CHECK (CRITICAL)
                if (!listNames.contains(selectedList)) {
                  selectedList =
                      listNames.contains('My Tasks') ? 'My Tasks' : null;
                }

                return DropdownButtonFormField<String>(
                  value: selectedList,
                  decoration: const InputDecoration(labelText: "List"),
                  items: listNames
                      .map(
                        (name) => DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedList = value);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
