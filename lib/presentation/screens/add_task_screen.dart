import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_manager_app/core/utils/ai_helper.dart';

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
  String selectedList = "My Tasks";

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

  void saveTask() async {
    await FirebaseFirestore.instance.collection('tasks').add({
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'dueDateTime': selectedDateTime, // ✅ DateTime → Timestamp
      'isCompleted': false,
      'isStarred': AIHelper.shouldStarTask(titleController.text),
      'listName': AIHelper.suggestList(titleController.text),

      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });

    Navigator.pop(context);
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
            icon: Icon(isStarred ? Icons.star : Icons.star_border),
            onPressed: () {
              setState(() => isStarred = !isStarred);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: "Add title"),
            ),
            const SizedBox(height: 10),

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

            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(hintText: "Add description"),
              maxLines: 3,
            ),

            const SizedBox(height: 10),

            DropdownButton<String>(
              value: selectedList,
              items: const [
                DropdownMenuItem(value: "My Tasks", child: Text("My Tasks")),
                DropdownMenuItem(value: "Work", child: Text("Work")),
                DropdownMenuItem(value: "Study", child: Text("Study")),
              ],
              onChanged: (value) {
                setState(() => selectedList = value!);
              },
            ),

            const Spacer(),

            
          ],
        ),
      ),
    );
  }
}
