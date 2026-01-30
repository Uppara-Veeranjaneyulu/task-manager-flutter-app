import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_app/presentation/widgets/create_list_dialog.dart';

import '../../data/models/task_model.dart';
import '../providers/theme_provider.dart';
import '../providers/list_provider.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import 'starred_tasks_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ MUST be here (not inside StreamBuilder)
    final selectedList = context.watch<ListProvider>().selectedList;

    return Scaffold(
      // 🔝 APP BAR
      appBar: AppBar(
        title: Text(selectedList ?? "All tasks"),

        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                onPressed: themeProvider.toggleTheme,
              );
            },
          ),
        ],
      ),

      // 📂 DRAWER
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text("Task Manager 📝", style: TextStyle(fontSize: 24)),
            ),

            // ✅ ALL TASKS
            ListTile(
              leading: const Icon(Icons.check),
              title: const Text("All tasks"),
              selected: context.watch<ListProvider>().selectedList == null,
              onTap: () {
                context.read<ListProvider>().showAllTasks();
                Navigator.pop(context);
              },
            ),

            // ⭐ STARRED
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text("Starred"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StarredTasksScreen()),
                );
              },
            ),

            const Divider(),

            // 📁 LISTS
            ExpansionTile(
              title: const Text("Lists"),
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('lists')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final listName = doc['name'];

                        return ListTile(
                          title: Text(listName),
                          selected:
                              context.watch<ListProvider>().selectedList ==
                              listName,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            onPressed: () async {
                              // move tasks to My Tasks before delete
                              final tasks = await FirebaseFirestore.instance
                                  .collection('tasks')
                                  .where('listName', isEqualTo: listName)
                                  .get();

                              for (var t in tasks.docs) {
                                t.reference.update({'listName': 'My Tasks'});
                              }

                              await doc.reference.delete();
                            },
                          ),
                          onTap: () {
                            context.read<ListProvider>().selectList(listName);
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    );
                  },
                ),

                // ➕ CREATE LIST
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text("Create new list"),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => const CreateListDialog(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),

      // ➕ ADD TASK
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );
        },
      ),

      // 📋 TASK LIST
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('listName', isEqualTo: selectedList)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No tasks added yet"));
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
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditTaskScreen(task: task),
                      ),
                    );
                  },
                  child: ListTile(
                    leading: Checkbox(
                      value: task.isCompleted,
                      onChanged: (value) {
                        FirebaseFirestore.instance
                            .collection('tasks')
                            .doc(task.id)
                            .update({
                              'isCompleted': value,
                              'updatedAt': Timestamp.now(),
                            });
                      },
                    ),

                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),

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

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (task.isStarred)
                          const Icon(Icons.star, color: Colors.amber),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('tasks')
                                .doc(task.id)
                                .delete();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
