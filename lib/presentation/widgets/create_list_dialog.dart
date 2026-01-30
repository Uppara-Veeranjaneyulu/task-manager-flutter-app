import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateListDialog extends StatefulWidget {
  const CreateListDialog({super.key});

  @override
  State<CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<CreateListDialog> {
  final TextEditingController controller = TextEditingController();

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> createList() async {
    final name = controller.text.trim();

    if (name.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('lists')
        .add({'name': name, 'createdAt': Timestamp.now()});

    Navigator.pop(context);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create new list"),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: "Enter list name"),
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
