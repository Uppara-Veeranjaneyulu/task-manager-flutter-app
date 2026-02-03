import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../data/models/task_model.dart';
import '../providers/theme_provider.dart';
import '../providers/list_provider.dart';
import '../widgets/create_list_dialog.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import 'starred_tasks_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../widgets/logout_dialog.dart';

import 'notification_settings_screen.dart';

import '../../core/services/local_notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    // 🔔 Phase 2 hook (safe to keep even if empty)
    // _applyNotificationSettings();
  }

  // 🔔 Phase 2 (we’ll activate later)
  /*
  Future<void> _applyNotificationSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) return;

    final notifications = doc['notifications'];
    if (notifications['dailyReminder'] == true) {
      final time = notifications['reminderTime'].split(':');
      await LocalNotificationService.scheduleDailyReminder(
        hour: int.parse(time[0]),
        minute: int.parse(time[1]),
      );
    } else {
      await LocalNotificationService.cancelDailyReminder();
    }
  }
  */

//   Future<void> showLogoutDialog(BuildContext context) async {
//   final shouldLogout = await showDialog<bool>(
//     context: context,
//     builder: (context) {
//       return AlertDialog(
//         title: const Text("Logout"),
//         content: const Text(
//           "Are you sure you want to logout?",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text(
//               "Logout",
//               style: TextStyle(color: Colors.red),
//             ),
//           ),
//         ],
//       );
//     },
//   );

//   if (shouldLogout == true) {
//     await FirebaseAuth.instance.signOut();

//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const LoginScreen()),
//       (_) => false,
//     );
//   }
// }


  @override
  Widget build(BuildContext context) {
    final selectedList = context.watch<ListProvider>().selectedList;

    // 🔹 USER-SCOPED TASK QUERY
    Query taskQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks');

    if (selectedList != null) {
      taskQuery = taskQuery.where('listName', isEqualTo: selectedList);
    }

    return Scaffold(
      // 🔝 APP BAR
      appBar: AppBar(
        title: Text(selectedList ?? "All tasks"),
        actions: [
          Consumer<ThemeProvider>(
            builder: (_, themeProvider, __) {
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
        child: SafeArea(
          child: Column(
            children: [
              const DrawerHeader(
                child: Text("Task Manager 📝", style: TextStyle(fontSize: 24)),
              ),

              // 📋 MAIN CONTENT
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // ✅ ALL TASKS
                    ListTile(
                      leading: const Icon(Icons.check),
                      title: const Text("All tasks"),
                      selected: selectedList == null,
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
                          MaterialPageRoute(
                            builder: (_) => const StarredTasksScreen(),
                          ),
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
                              .collection('users')
                              .doc(uid)
                              .collection('lists')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox();
                            }

                            return Column(
                              children: snapshot.data!.docs.map((doc) {
                                final listName = doc['name'] as String;

                                return ListTile(
                                  title: Text(listName),
                                  selected: selectedList == listName,
                                  onTap: () {
                                    context.read<ListProvider>().selectList(
                                      listName,
                                    );
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

              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text("Notifications"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen(),
                    ),
                  );
                },
              ),


              // 🔻 BOTTOM ACTIONS
              const Divider(),

              // 👤 PROFILE
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Profile"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),

              // 🚪 LOGOUT
              ListTile(
  leading: const Icon(Icons.logout, color: Colors.red),
  title: const Text(
    "Logout",
    style: TextStyle(color: Colors.red),
  ),
  onTap: () async {
    Navigator.pop(context); // close drawer
    await showLogoutDialog(context);
  },
),


            ],
          ),
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
        stream: taskQuery.orderBy('createdAt', descending: true).snapshots(),
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
                child: ListTile(
                  leading: Checkbox(
                    value: task.isCompleted,
                    onChanged: (value) {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
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
                  subtitle: task.description.isNotEmpty
                      ? Text(
                          task.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (task.isStarred)
                        const Icon(Icons.star, color: Colors.amber),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('tasks')
                              .doc(task.id)
                              .delete();
                        },
                      ),
                    ],
                  ),
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
