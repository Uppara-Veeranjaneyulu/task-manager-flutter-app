import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser!;
    final uid = user.uid;

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    await user.reauthenticateWithCredential(cred);

    await _db.collection('users').doc(uid).collection('tasks').get().then((
      snap,
    ) {
      for (var d in snap.docs) {
        d.reference.delete();
      }
    });

    await _db.collection('users').doc(uid).collection('lists').get().then((
      snap,
    ) {
      for (var d in snap.docs) {
        d.reference.delete();
      }
    });

    await _db.collection('users').doc(uid).delete();
    await user.delete();
  }
}
