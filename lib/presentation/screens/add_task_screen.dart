import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    ensureDefaultListExists();
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

    await FirebaseFirestore.instance
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
              decoration: const InputDecoration(hintText: "Add title"),
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
              decoration: const InputDecoration(hintText: "Add description"),
              maxLines: 3,
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
                  return const CircularProgressIndicator();
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
          ],
        ),
      ),
    );
  }
}
