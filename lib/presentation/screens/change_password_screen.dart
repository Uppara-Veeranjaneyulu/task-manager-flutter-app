import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../../core/utils/validators.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  bool loading = false;

  Future<void> changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => loading = true);

      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _oldController.text.trim(),
      );

      // 🔐 RE-AUTH REQUIRED
      await user.reauthenticateWithCredential(cred);

      await user.updatePassword(_newController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password updated successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().split(']').last.trim()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Security Settings"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Update Password",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Keep your account secure with a strong password.",
                  style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                ),
                const SizedBox(height: 32),

                CustomTextField(
                  controller: _oldController,
                  label: "Current Password",
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: (val) => val == null || val.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 20),

                CustomTextField(
                  controller: _newController,
                  label: "New Password",
                  prefixIcon: Icons.lock_reset_rounded,
                  isPassword: true,
                  validator: AppValidators.password,
                ),
                const SizedBox(height: 40),

                CustomButton(
                  onPressed: changePassword,
                  text: "UPDATE PASSWORD",
                  isLoading: loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
