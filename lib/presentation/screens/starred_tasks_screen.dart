import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/task_model.dart';
import 'edit_task_screen.dart';

class StarredTasksScreen extends StatelessWidget {
  const StarredTasksScreen({super.key});

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Starred")),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('tasks')
            .where('isStarred', isEqualTo: true)
            .orderBy('updatedAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No starred tasks"));
          }

          final tasks = snapshot.data!.docs.map((doc) {
            return TaskModel.fromFirestore(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                child: ListTile(
                  // ⭐ UNSTAR
                  leading: IconButton(
                    icon: const Icon(Icons.star, color: Colors.amber),
                    onPressed: () {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('tasks')
                          .doc(task.id)
                          .update({
                            'isStarred': false,
                            'updatedAt': Timestamp.now(),
                          });
                    },
                  ),

                  // 📝 TITLE
                  title: Text(task.title),

                  // 📄 DESCRIPTION / DATE
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (task.dueDateTime != null)
                        Text(
                          "Due: ${task.dueDateTime!.day}/${task.dueDateTime!.month} "
                          "${task.dueDateTime!.hour.toString().padLeft(2, '0')}:"
                          "${task.dueDateTime!.minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (task.description.isNotEmpty)
                        Text(
                          task.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),

                  // ✏️ EDIT TASK
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditTaskScreen(task: task),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
