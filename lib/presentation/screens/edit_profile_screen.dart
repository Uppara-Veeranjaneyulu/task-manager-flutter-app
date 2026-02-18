import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  XFile? selectedImage;
  bool loading = false;

  late TextEditingController nameController;

  final user = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: user.displayName ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  /// 📷 PICK IMAGE
  Future<void> pickImage() async {
    final picker = ImagePicker();

    final result = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (result != null) {
      setState(() {
        selectedImage = result;
      });
    }
  }

  /// 💾 SAVE PROFILE
  Future<void> saveProfile() async {
    setState(() => loading = true);

    try {
      String? photoUrl;

        // 🔹 Upload photo if changed
      // 🔹 Upload photo if changed
      if (selectedImage != null) {
        print("🖼️ Selected image found. Uploading...");
        photoUrl = await ProfileService.uploadProfilePhoto(selectedImage!);
        print("✅ Photo uploaded. URL: $photoUrl");
        
        print("🔄 Updating Firestore profile...");
        await ProfileService.updateProfilePhoto(photoUrl);
        
        print("🔄 Updating Auth profile...");
        await user.updatePhotoURL(photoUrl); // Sync with Auth
        print("✅ All profile updates complete.");
      }

      // 🔹 Update name if changed
      final newName = nameController.text.trim();
      if (newName.isNotEmpty && newName != user.displayName) {
        await user.updateDisplayName(newName);

        await ProfileService.updateProfileName(newName);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 👤 PHOTO
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: selectedImage != null
                    ? (kIsWeb
                        ? NetworkImage(selectedImage!.path)
                        : FileImage(File(selectedImage!.path)) as ImageProvider)
                    : (user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null),
                child: selectedImage == null && user.photoURL == null
                    ? const Icon(Icons.camera_alt, size: 30)
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            // ✏️ NAME
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            // 💾 SAVE
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : saveProfile,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
