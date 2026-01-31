import 'package:flutter/material.dart';
import 'package:task_manager_app/presentation/screens/phone_login_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/google_auth_service.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
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
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),

            TextButton(
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

            const SizedBox(height: 20),
            
            ElevatedButton(onPressed: login, child: const Text("Login")),
            Text("or"),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text("Sign in with Google"),
              onPressed: () async {
                try {
                  await GoogleAuthService.signInWithGoogle();
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

            TextButton.icon(
              icon: const Icon(Icons.phone),
              label: const Text("Sign in with Mobile"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
                );
              },
            ),

            const SizedBox(height: 20),
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
