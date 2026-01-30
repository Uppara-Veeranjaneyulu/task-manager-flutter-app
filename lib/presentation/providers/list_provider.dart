import 'package:flutter/material.dart';

class ListProvider extends ChangeNotifier {
  String? selectedList; // null = All tasks

  void showAllTasks() {
    selectedList = null;
    notifyListeners();
  }

  void selectList(String listName) {
    selectedList = listName;
    notifyListeners();
  }
}
