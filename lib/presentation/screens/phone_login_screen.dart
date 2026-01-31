import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';  
import 'package:flutter/foundation.dart' show kIsWeb;


class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  ConfirmationResult? confirmationResult;
  bool otpSent = false;
  bool loading = false;

  @override
  void initState() {
    super.initState();

    /// 🔐 REQUIRED FOR WEB
    html.DivElement div = html.DivElement()..id = 'recaptcha-container';
    html.document.body!.append(div);
  }

  Future<void> sendOTP() async {
    final phone = phoneController.text.trim();

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid 10-digit number")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      confirmationResult = await FirebaseAuth.instance.signInWithPhoneNumber(
        "+91$phone",
        RecaptchaVerifier(
          container: 'recaptcha-container',
          size: RecaptchaVerifierSize.invisible,
        ),
      );

      setState(() => otpSent = true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  Future<void> verifyOTP() async {
    try {
      await confirmationResult!.confirm(otpController.text.trim());

      Navigator.pop(context); // Firebase auth listener handles redirect
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login with Mobile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Mobile number"),
            ),

            if (otpSent) ...[
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "OTP"),
              ),
            ],

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading
                  ? null
                  : otpSent
                  ? verifyOTP
                  : sendOTP,
              child: loading
                  ? const CircularProgressIndicator()
                  : Text(otpSent ? "Verify OTP" : "Send OTP"),
            ),

            /// 👇 REQUIRED INVISIBLE CONTAINER
            const SizedBox(height: 10),
            const Text("", key: Key('recaptcha-container')),
          ],
        ),
      ),
    );
  }
}
