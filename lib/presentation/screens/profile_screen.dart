import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'notification_settings_screen.dart';
import 'login_screen.dart' as import_login;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String get uid => FirebaseAuth.instance.currentUser!.uid;



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
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

          return CustomScrollView(
            slivers: [
              // 🎨 GRADIENT HEADER
              SliverAppBar(
                expandedHeight: 280.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark 
                            ? [colorScheme.primaryContainer, colorScheme.secondaryContainer]
                            : [Colors.blue, Colors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: (data['photoUrl'] ?? '').toString().isNotEmpty
                                    ? NetworkImage(data['photoUrl'])
                                    : null,
                            backgroundColor: isDark ? colorScheme.surface : Colors.white,
                            child: (data['photoUrl'] ?? '').toString().isEmpty
                                ? Icon(Icons.person, size: 50, color: isDark ? colorScheme.onSurface : Colors.grey)
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            data['name'] ?? 'User',
                            style: TextStyle(
                              color: isDark ? colorScheme.onPrimaryContainer : Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            data['email'] ?? '',
                            style: TextStyle(
                              color: isDark ? colorScheme.onPrimaryContainer.withOpacity(0.7) : Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 📊 STATS CARDS
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('tasks')
                            .snapshots(),
                        builder: (context, taskSnapshot) {
                          if (!taskSnapshot.hasData) {
                            return const LinearProgressIndicator();
                          }
                          final tasks = taskSnapshot.data!.docs;
                          final total = tasks.length;
                          final completed = tasks.where((doc) => doc['isCompleted'] == true).length;
                          final pending = total - completed;

                          return Row(
                            children: [
                              _buildStatCard(
                                "Total", 
                                total.toString(), 
                                isDark ? colorScheme.primaryContainer : Colors.blue.shade100, 
                                isDark ? colorScheme.onPrimaryContainer : Colors.blue,
                              ),
                              const SizedBox(width: 10),
                              _buildStatCard(
                                "Done", 
                                completed.toString(), 
                                isDark ? colorScheme.secondaryContainer : Colors.green.shade100, 
                                isDark ? colorScheme.onSecondaryContainer : Colors.green,
                              ),
                              const SizedBox(width: 10),
                              _buildStatCard(
                                "Pending", 
                                pending.toString(), 
                                isDark ? colorScheme.tertiaryContainer : Colors.orange.shade100, 
                                isDark ? colorScheme.onTertiaryContainer : Colors.orange,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // 🛠 ACTION MENU
                      _buildMenuCard(
                        context,
                        icon: Icons.edit,
                        title: "Edit Profile",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                        ),
                      ),
                      _buildMenuCard(
                        context,
                        icon: Icons.notifications,
                        title: "Notifications",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                        ),
                      ),
                      _buildMenuCard(
                        context,
                        icon: Icons.lock,
                        title: "Change Password",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                        ),
                      ),
                      _buildMenuCard(
                        context,
                        icon: Icons.delete,
                        title: "Delete Account",
                        isDestructive: true,
                        onTap: () => _showDeleteConfirmation(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      bool isDestructive = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            spreadRadius: 1,
            blurRadius: 5,
          )
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive 
                ? (isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50) 
                : (isDark ? colorScheme.primary.withOpacity(0.2) : Colors.blue.shade50),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon, 
            color: isDestructive ? Colors.red : (isDark ? colorScheme.primary : Colors.blue),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : colorScheme.onSurface,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurface.withOpacity(0.5)),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
            "Are you sure you want to delete your account? This action cannot be undone and all your data will be lost."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();
        await FirebaseAuth.instance.currentUser?.delete();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const import_login.LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete account: $e")),
          );
        }
      }
    }
  }

}
