import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';

import '../screens/login_screen.dart';

Future<void> showLogoutDialog(BuildContext context) async {
  bool loading = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Logout"),
            content: loading
                ? const SizedBox(
                    height: 60,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const Text("Are you sure you want to logout?"),
            actions: loading
                ? []
                : [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      child: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () async {
                        setState(() => loading = true);

                        // 🔐 OPTIONAL BIOMETRIC (FAIL-SAFE)
                        final auth = LocalAuthentication();
                        try {
                          final canAuth =
                              await auth.canCheckBiometrics &&
                              await auth.isDeviceSupported();

                          if (canAuth) {
                            await auth.authenticate(
                              localizedReason: 'Confirm logout',
                              options: const AuthenticationOptions(
                                biometricOnly: false,
                                stickyAuth: false,
                              ),
                            );
                          }
                        } catch (_) {
                          // ❗ Ignore biometric errors (DO NOT BLOCK LOGOUT)
                        }

                        // ✅ CLOSE DIALOG FIRST
                        Navigator.pop(dialogContext);

                        // 🔥 SIGN OUT
                        await FirebaseAuth.instance.signOut();

                        // 🔁 RESET APP
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (_) => false,
                        );
                      },
                    ),
                  ],
          );
        },
      );
    },
  );
}
