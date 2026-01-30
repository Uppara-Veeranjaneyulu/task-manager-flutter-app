import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/task_model.dart';

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

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.task.title);
    descriptionController =
        TextEditingController(text: widget.task.description);

    selectedDateTime = widget.task.dueDateTime;
    isStarred = widget.task.isStarred;
    selectedList = widget.task.listName;
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
      'updatedAt': Timestamp.now(),
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
