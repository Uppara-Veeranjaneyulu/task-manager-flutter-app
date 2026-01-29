class TaskListModel {
  final String id;
  final String name;

  TaskListModel({required this.id, required this.name});

  factory TaskListModel.fromFirestore(Map<String, dynamic> data, String id) {
    return TaskListModel(id: id, name: data['name']);
  }
}
