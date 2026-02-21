import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/task_model.dart';
import 'edit_task_screen.dart';

class TaskSearchScreen extends StatefulWidget {
  const TaskSearchScreen({super.key});

  @override
  State<TaskSearchScreen> createState() => _TaskSearchScreenState();
}

class _TaskSearchScreenState extends State<TaskSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 200,
            width: 200,
            child: Lottie.network(
              'https://assets9.lottiefiles.com/packages/lf20_glp9al9p.json',
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.search_off, size: 100, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No search results',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try searching for something else',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Search for notes or tasks...',
            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
            border: InputBorder.none,
          ),
          onChanged: (val) {
            setState(() => _searchQuery = val);
          },
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            ),
        ],
      ),
      body: _searchQuery.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 80, color: colorScheme.onSurface.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('Type to start searching...',
                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 16)),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_uid)
                  .collection('tasks')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildNoResultsState();
                }

                final results = snapshot.data!.docs
                    .map((doc) => TaskModel.fromFirestore(
                        doc.data() as Map<String, dynamic>, doc.id))
                    .where((task) {
                  final query = _searchQuery.toLowerCase();
                  return task.title.toLowerCase().contains(query) ||
                      task.description.toLowerCase().contains(query);
                }).toList();

                if (results.isEmpty) {
                  return _buildNoResultsState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final task = results[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Icon(
                          task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                          color: task.isCompleted ? Colors.green : colorScheme.primary,
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: task.isCompleted ? colorScheme.onSurface.withOpacity(0.5) : colorScheme.onSurface,
                          ),
                        ),
                        subtitle: task.description.isNotEmpty
                            ? Text(
                                task.description, 
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                              )
                            : null,
                        trailing: task.isStarred ? const Icon(Icons.star, color: Colors.amber, size: 20) : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EditTaskScreen(task: task)),
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
