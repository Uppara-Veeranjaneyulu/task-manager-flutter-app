import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  // 🔢 PROFILE COMPLETION
  int calculateProfileCompletion(Map<String, dynamic> data) {
    int completed = 0;

    if ((data['name'] ?? '').toString().isNotEmpty) completed++;
    if ((data['email'] ?? '').toString().isNotEmpty) completed++;
    if ((data['phone'] ?? '').toString().isNotEmpty) completed++;
    if ((data['photoUrl'] ?? '').toString().isNotEmpty) completed++;

    return (completed / 4 * 100).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.data() == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final completion = calculateProfileCompletion(data);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 👤 AVATAR
                CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      (data['photoUrl'] ?? '').toString().isNotEmpty
                      ? NetworkImage(data['photoUrl'])
                      : null,
                  child: (data['photoUrl'] ?? '').toString().isEmpty
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),

                const SizedBox(height: 16),

                // 👤 NAME
                Text(
                  data['name'] ?? 'User',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // 📧 EMAIL
                Text(
                  data['email'] ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 20),

                // 📊 PROFILE COMPLETION
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Profile completion: $completion%"),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: completion / 100,
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ✏️ EDIT PROFILE
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit Profile"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                const Divider(),

                // 🔔 NOTIFICATIONS
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text("Notification Settings"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),

                // 🔐 CHANGE PASSWORD
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text("Change Password"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),

                // 🗑 DELETE ACCOUNT (UI ONLY FOR NOW)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    "Delete Account",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    // Next step: confirmation + password dialog
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
