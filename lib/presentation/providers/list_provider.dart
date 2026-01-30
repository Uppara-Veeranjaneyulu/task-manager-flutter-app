import 'package:flutter/material.dart';

class ListProvider extends ChangeNotifier {
  String? selectedList; // 👈 NULL = All tasks

  // 📂 SELECT SPECIFIC LIST
  void selectList(String listName) {
    selectedList = listName;
    notifyListeners();
  }

  // ✅ SHOW ALL TASKS
  void showAllTasks() {
    selectedList = null;
    notifyListeners();
  }
}
