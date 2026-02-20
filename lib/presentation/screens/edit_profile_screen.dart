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
      imageQuality: 70,   // compress quality
      maxWidth: 600,      // cap width  → profile pics don't need to be huge
      maxHeight: 600,     // cap height → keeps upload size tiny (~30-80 KB)
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

      if (selectedImage != null) {
        print("🖼️ Uploading photo...");
        photoUrl = await ProfileService.uploadProfilePhoto(selectedImage!);
        print("✅ Photo uploaded: $photoUrl");

        // Fire Firestore + Auth updates in background — don't block navigation
        ProfileService.updateProfilePhoto(photoUrl);
        user.updatePhotoURL(photoUrl);
      }

      // Update name in background too
      final newName = nameController.text.trim();
      if (newName.isNotEmpty && newName != user.displayName) {
        user.updateDisplayName(newName);
        ProfileService.updateProfileName(newName);
      }


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  selectedImage != null
                      ? 'Profile photo updated successfully!'
                      : 'Profile updated successfully!',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
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
