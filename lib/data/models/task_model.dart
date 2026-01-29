import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDateTime;
  final bool isCompleted;
  final bool isStarred;
  final String listName;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDateTime,
    required this.isCompleted,
    required this.isStarred,
    required this.listName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return TaskModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDateTime: parseDate(data['dueDateTime']),
      isCompleted: data['isCompleted'] ?? false,
      isStarred: data['isStarred'] ?? false,
      listName: data['listName'] ?? 'My Tasks',
      createdAt: parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: parseDate(data['updatedAt']) ?? DateTime.now(),
    );
  }
}
