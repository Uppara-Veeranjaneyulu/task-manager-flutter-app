import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'register_screen.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';

import '../../core/services/google_auth_service.dart';
import '../../core/services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // 🔐 EMAIL + PASSWORD LOGIN
  Future<void> login() async {
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = result.user!;
      await UserService.createUserIfNotExists(user); // ✅ FIXED

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📧 EMAIL
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            // 🔑 PASSWORD
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),

            // 🔁 FORGOT PASSWORD
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: const Text("Forgot password?"),
              ),
            ),

            const SizedBox(height: 20),

            // 🔐 LOGIN BUTTON
            ElevatedButton(onPressed: login, child: const Text("Login")),

            const SizedBox(height: 8),
            const Text("or"),
            const SizedBox(height: 8),

            // 🔵 GOOGLE LOGIN
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text("Sign in with Google"),
              onPressed: () async {
                try {
                  final result = await GoogleAuthService.signInWithGoogle();

                  await UserService.createUserIfNotExists(
                    result.user!,
                  ); // ✅ FIXED

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
            ),

            const SizedBox(height: 20),

            // 🆕 REGISTER
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }
}
