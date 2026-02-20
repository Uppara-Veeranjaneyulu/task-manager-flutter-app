import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_screen.dart';
import 'home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still initializing — show spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Use stream data OR the synchronously-cached currentUser.
        // Firebase briefly emits null before it finishes reading the
        // persisted token from disk — this fallback prevents the login
        // screen from flashing on every cold start.
        final user = snapshot.data ?? FirebaseAuth.instance.currentUser;

        if (user != null) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
