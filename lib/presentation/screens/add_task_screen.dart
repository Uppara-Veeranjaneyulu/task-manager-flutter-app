import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../core/services/ai_service.dart';
import '../../core/services/voice_service.dart';
import '../../core/services/local_notification_service.dart';
import '../../core/services/background_service.dart';
import 'qr_scanner_screen.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  DateTime? selectedDateTime;
  bool isStarred = false;
  String selectedList = "";
  String selectedPriority = "Medium"; // Default priority

  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    ensureDefaultListExists();
    _initVoice();
    
    // AI Prediction Listener
    titleController.addListener(_updateAI);
    descriptionController.addListener(_updateAI);
  }

  void _initVoice() async {
    await _voiceService.init();
    setState(() {});
  }

  void _updateAI() {
    // Basic debounce could be added here
    final priority = AIService.predictPriority(titleController.text, descriptionController.text);
    if (priority != selectedPriority) {
       // Only auto-update if user hasn't manually changed it? 
       // For now, let's just update it to show off the AI.
       if (mounted) setState(() => selectedPriority = priority); 
    }

    final category = AIService.suggestCategory(titleController.text);
    // If we had categories mapped to lists, we could auto-select list.
    // For now, we just print or could try to match 'listName' if it exists.
  }

  void _startListening() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _voiceService.startListening(onResult: (text) {
        // Simple logic: if empty, set title. If title exists, append to description.
        if (titleController.text.isEmpty) {
          titleController.text = text;
        } else {
          descriptionController.text = text;
        }
        setState(() => _isListening = false);
      });
    }
  }

  Future<void> _scanQR() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
    );

    if (result != null && result is String) {
       try {
         // Attempt to parse result as JSON
         final Map<String, dynamic> data = jsonDecode(result);
         
         if (data.containsKey('title')) {
           titleController.text = data['title'].toString();
         }
         if (data.containsKey('description')) {
           descriptionController.text = data['description'].toString();
         } else if (!data.containsKey('title')) {
           // If it's valid JSON but doesn't have title/desc, dump it in description
           descriptionController.text = result;
         }
         
         setState(() {});
       } catch (e) {
         // Fallback: If not valid JSON, treat as Title
         setState(() {
           titleController.text = result;
         });
       }
    }
  }

  Future<void> ensureDefaultListExists() async {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('lists');

    final snapshot = await ref.get();

    if (snapshot.docs.isEmpty) {
      await ref.add({'name': 'My Tasks'});
    }
  }

  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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

  Future<void> saveTask() async {
    if (titleController.text.trim().isEmpty || selectedList.isEmpty) return;

    int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (selectedDateTime != null) {
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
        // Workmanager works best with delays > 15 mins but can work sooner in debug.
        // We'll schedule it.
        if (delay.inSeconds > 0) {
           await BackgroundService.scheduleEmailTask(
            id: notificationId,
            toEmail: FirebaseAuth.instance.currentUser?.email ?? "unknown@user.com",
            subject: "Reminder: ${titleController.text}",
            body: "Your task '${titleController.text}' is due at $selectedDateTime.",
            initialDelay: delay,
          );
        }
      }
    }

    // Fire Firestore write in background — don't block navigation
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('tasks')
        .add({
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'dueDateTime': selectedDateTime,
          'isCompleted': false,
          'isStarred': isStarred,
          'listName': selectedList,
          'priority': selectedPriority,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'notificationId': notificationId,
        });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Task created!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: saveTask,
        child: const Icon(Icons.check),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      appBar: AppBar(
        title: const Text("Add task"),
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : null),
            onPressed: _startListening,
            tooltip: "Voice Input",
          ),
           IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanQR,
            tooltip: "Scan QR",
          ),
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

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: "Add title",
                labelText: "Title (AI predicts priority)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

             TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                hintText: "Add description",
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(labelText: "Priority"),
                    items: ['Low', 'Medium', 'High'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => selectedPriority = val!),
                  ),
                ),
                const SizedBox(width: 12),
                 Expanded(
                   child: InkWell(
                    onTap: pickDateTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Due Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        selectedDateTime != null
                            ? "${selectedDateTime!.day}/${selectedDateTime!.month} ${selectedDateTime!.hour}:${selectedDateTime!.minute.toString().padLeft(2, '0')}"
                            : 'No Date',
                      ),
                    ),
                ),
                 ),
              ],
            ),

            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUserId)
                  .collection('lists')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }

                final listDocs = snapshot.data!.docs;

                if (listDocs.isEmpty) {
                  return const Text("No lists available");
                }

                if (!listDocs.any((doc) => doc['name'] == selectedList)) {
                  selectedList = listDocs.first['name'];
                }

                return DropdownButtonFormField<String>(
                  value: selectedList,
                  decoration: const InputDecoration(labelText: "List"),
                  items: listDocs.map((doc) {
                    final name = doc['name'] as String;
                    return DropdownMenuItem(value: name, child: Text(name));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedList = value!);
                  },
                );
              },
            ),
             const SizedBox(height: 20),
             if (titleController.text.isNotEmpty)
                Text(
                  "AI Suggested Category: ${AIService.suggestCategory(titleController.text)}",
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
          ],
        ),
      ),
    );
  }
}
