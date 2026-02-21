import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/task_model.dart';
import '../providers/theme_provider.dart';
import '../providers/list_provider.dart';
import '../widgets/create_list_dialog.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import 'starred_tasks_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'ai_assistant_screen.dart';
import 'task_search_screen.dart';
import 'notification_settings_screen.dart';
import '../../core/services/local_notification_service.dart';
import '../widgets/logout_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// 🕐 Isolated clock widget — only this tiny widget rebuilds every second
class _LiveClock extends StatefulWidget {
  const _LiveClock();
  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final date = '${days[_now.weekday - 1]}, ${_now.day} ${months[_now.month - 1]} ${_now.year}';
    final time = '${_now.hour.toString().padLeft(2,'0')}:${_now.minute.toString().padLeft(2,'0')}:${_now.second.toString().padLeft(2,'0')}';
    return Text(
      '$date  •  $time',
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Widget _buildTaskList(BuildContext context, String uid, Query baseQuery, bool completed) {
    final query = baseQuery.where('isCompleted', isEqualTo: completed);
    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: Lottie.network(
                    'https://assets10.lottiefiles.com/packages/lf20_w51pcehl.json',
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(completed ? Icons.check_circle_outline : Icons.inbox,
                            size: 100, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  completed ? 'No completed tasks yet' : 'No tasks added yet',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final tasks = snapshot.data!.docs
            .map((doc) => TaskModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: completed
                    ? IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                        tooltip: 'Mark as active',
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('users').doc(uid).collection('tasks').doc(task.id)
                              .update({'isCompleted': false, 'updatedAt': Timestamp.now()});
                        },
                      )
                    : Checkbox(
                        value: false,
                        activeColor: Colors.green,
                        onChanged: (_) {
                          FirebaseFirestore.instance
                              .collection('users').doc(uid).collection('tasks').doc(task.id)
                              .update({'isCompleted': true, 'updatedAt': Timestamp.now()});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 10),
                                Text('Task marked as completed!'),
                              ]),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    decoration: completed ? TextDecoration.lineThrough : null,
                    color: completed ? Colors.grey : null,
                  ),
                ),
                subtitle: task.description.isNotEmpty
                    ? Text(task.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: completed ? Colors.grey : null))
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (task.isStarred) const Icon(Icons.star, color: Colors.amber),
                    IconButton(
                      icon: const Icon(Icons.share, size: 20),
                      onPressed: () => Share.share('${task.title}\n${task.description}'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Task'),
                            content: const Text('Are you sure you want to delete this task?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection('users').doc(uid).collection('tasks').doc(task.id)
                                      .delete();
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(children: [
                                        Icon(Icons.delete, color: Colors.white),
                                        SizedBox(width: 10),
                                        Text('Task deleted!'),
                                      ]),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                onTap: completed ? null : () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => EditTaskScreen(task: task)));
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedList = context.watch<ListProvider>().selectedList;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    Query baseQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks');

    if (selectedList != null) {
      baseQuery = baseQuery.where('listName', isEqualTo: selectedList);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selectedList ?? 'All Tasks',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const _LiveClock(),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.checklist), text: 'Active'),
              Tab(icon: Icon(Icons.check_circle_outline), text: 'Completed'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TaskSearchScreen()),
                );
              },
            ),
            Consumer<ThemeProvider>(
              builder: (_, themeProvider, __) => IconButton(
                icon: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                onPressed: themeProvider.toggleTheme,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.psychology_outlined),
              tooltip: 'AI Assistant',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                const DrawerHeader(
                  child: Text("Task Manager 📝", style: TextStyle(fontSize: 24)),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.check),
                        title: const Text("All tasks"),
                        selected: selectedList == null,
                        onTap: () {
                          context.read<ListProvider>().showAllTasks();
                          Navigator.pop(context);
                        },
                      ),
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
                                  final docId = doc.id;
                                  return ListTile(
                                    title: Text(listName),
                                    selected: selectedList == listName,
                                    onTap: () {
                                      context.read<ListProvider>().selectList(listName);
                                      Navigator.pop(context);
                                    },
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete List'),
                                            content: Text('Delete "$listName"? Tasks in this list will not be deleted.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  FirebaseFirestore.instance
                                                      .collection('users')
                                                      .doc(uid)
                                                      .collection('lists')
                                                      .doc(docId)
                                                      .delete();
                                                  if (selectedList == listName) {
                                                    context.read<ListProvider>().showAllTasks();
                                                  }
                                                  Navigator.pop(ctx);
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Row(children: [
                                                        const Icon(Icons.delete, color: Colors.white),
                                                        const SizedBox(width: 10),
                                                        Text('"$listName" deleted!'),
                                                      ]),
                                                      backgroundColor: Colors.red,
                                                      behavior: SnackBarBehavior.floating,
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                },
                                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
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
                const Divider(),
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
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Logout", style: TextStyle(color: Colors.red)),
                  onTap: () => showLogoutDialog(context),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const AddTaskScreen(),
                transitionsBuilder: (_, animation, __, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  );
                },
              ),
            );
          },
        ),
        body: TabBarView(
          children: [
            _buildTaskList(context, uid, baseQuery, false),
            _buildTaskList(context, uid, baseQuery, true),
          ],
        ),
      ),
    );
  }
}
