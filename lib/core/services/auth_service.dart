import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static Future<void> logoutFromAllDevices() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await user.getIdToken(true); // revoke tokens
    await FirebaseAuth.instance.signOut();
  }
}
