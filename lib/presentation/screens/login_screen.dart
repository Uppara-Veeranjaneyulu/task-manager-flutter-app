import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import 'register_screen.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';

import '../../core/services/google_auth_service.dart';
import '../../core/services/user_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // 🔐 EMAIL + PASSWORD LOGIN
  Future<void> login() async {
    setState(() => isLoading = true);
    debugPrint("Attempting login with: ${emailController.text.trim()}");
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      debugPrint("Firebase Auth success: ${result.user?.uid}");
      final user = result.user!;
      
      // Fire Firestore update in background — don't block navigation on it
      UserService.createUserIfNotExists(user);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint("Login Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Failed: ${e.toString().split(']').last.trim()}"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🎨 LAYER 1: Sophisticated Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF8FAFC), // Slate 50
                  Color(0xFFEFF6FF), // Blue 50
                  Color(0xFFF8FAFC),
                ],
              ),
            ),
          ),
          
          // 🫧 LAYER 2: Abstract Decorative Shapes
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.05),
              ),
            ),
          ),

          // 📄 LAYER 3: Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // 🏷️ LOGO SECTION
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 1),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.12),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 70,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ✨ WELCOME TEXT (Staggered)
                    _buildAnimatedItem(
                      intervalStart: 0.2,
                      child: const Column(
                        children: [
                          Text(
                            "Welcome Back",
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Manage your daily flow with ease",
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // 🧩 FORM SECTION
                    _buildAnimatedItem(
                      intervalStart: 0.4,
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: emailController,
                            label: "Email Address",
                            prefixIcon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: passwordController,
                            label: "Password",
                            prefixIcon: Icons.lock_open_rounded,
                            isPassword: true,
                          ),
                        ],
                      ),
                    ),

                    // 🔁 FORGOT PASSWORD
                    _buildAnimatedItem(
                      intervalStart: 0.5,
                      child: Align(
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
                          child: Text(
                            "Forgot password?",
                            style: TextStyle(
                              color: Colors.blueAccent.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 🔐 LOGIN BUTTON
                    _buildAnimatedItem(
                      intervalStart: 0.6,
                      child: CustomButton(
                        onPressed: login,
                        text: "Sign In",
                        isLoading: isLoading,
                      ),
                    ),

                    const SizedBox(height: 32),

                    _buildAnimatedItem(
                      intervalStart: 0.7,
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: Colors.blueGrey.shade100)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "continue with",
                              style: TextStyle(
                                color: Colors.blueGrey.shade300,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.blueGrey.shade100)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 🔵 GOOGLE LOGIN
                    _buildAnimatedItem(
                      intervalStart: 0.8,
                      child: SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: OutlinedButton.icon(
                          icon: Image.asset(
                            'assets/google_logo.png',
                            height: 22,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
                          ),
                          label: const Text(
                            "Google Account",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.blueGrey.shade100),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Colors.white,
                            elevation: 0,
                          ),
                          onPressed: () async {
                            try {
                              final result = await GoogleAuthService.signInWithGoogle();
                              UserService.createUserIfNotExists(result.user!);
                              if (mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 🆕 REGISTER link at the very bottom
                    _buildAnimatedItem(
                      intervalStart: 0.9,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "New here? ",
                            style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: const Text(
                              "Create Account",
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedItem({required double intervalStart, required Widget child}) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: Interval(intervalStart, intervalStart + 0.3, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(intervalStart, intervalStart + 0.3, curve: Curves.easeOutCubic),
          ),
        ),
        child: child,
      ),
    );
  }
}
