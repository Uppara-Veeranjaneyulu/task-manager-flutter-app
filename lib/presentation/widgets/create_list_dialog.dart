import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateListDialog extends StatefulWidget {
  const CreateListDialog({super.key});

  @override
  State<CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<CreateListDialog> {
  final controller = TextEditingController();

  void createList() async {
    if (controller.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('lists').add({
      'name': controller.text.trim(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create new list"),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: "Enter name"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(onPressed: createList, child: const Text("Done")),
      ],
    );
  }
}
