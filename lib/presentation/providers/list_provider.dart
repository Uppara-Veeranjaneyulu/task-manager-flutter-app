import 'package:flutter/material.dart';

class ListProvider extends ChangeNotifier {
  String selectedList = "My Tasks";

  void changeList(String listName) {
    selectedList = listName;
    notifyListeners();
  }
}
