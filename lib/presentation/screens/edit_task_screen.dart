import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/task_model.dart';

class EditTaskScreen extends StatefulWidget {
  final TaskModel task;
  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  DateTime? selectedDateTime;
  bool isStarred = false;
  String selectedList = "My Tasks";

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task.title);
    descriptionController = TextEditingController(
      text: widget.task.description,
    );
    selectedDateTime = widget.task.dueDateTime;
    isStarred = widget.task.isStarred;
    selectedList = widget.task.listName;
  }

  // 📅 PICK DATE & TIME
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

  // 💾 UPDATE TASK
  void updateTask() async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.task.id)
        .update({
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'dueDateTime': selectedDateTime,
          'isStarred': isStarred,
          'listName': selectedList,
          'updatedAt': Timestamp.now(),
        });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔝 APP BAR
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

      // 💾 SAVE BUTTON (BOTTOM-RIGHT)
      floatingActionButton: FloatingActionButton(
        onPressed: updateTask,
        child: const Icon(Icons.check),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // 🧾 BODY
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 📝 TITLE
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: "Task title"),
            ),

            const SizedBox(height: 12),

            // ⏰ DATE & TIME
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

            // 📄 DESCRIPTION
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(hintText: "Description"),
              maxLines: 3,
            ),

            const SizedBox(height: 12),

            // 📂 LIST DROPDOWN
            DropdownButtonFormField<String>(
              value: selectedList,
              decoration: const InputDecoration(labelText: "List"),
              items: const [
                DropdownMenuItem(value: "My Tasks", child: Text("My Tasks")),
                DropdownMenuItem(value: "Work", child: Text("Work")),
                DropdownMenuItem(value: "Study", child: Text("Study")),
              ],
              onChanged: (value) {
                setState(() => selectedList = value!);
              },
            ),
          ],
        ),
      ),
    );
  }
}
