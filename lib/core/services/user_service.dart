import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> createUserIfNotExists(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'photoUrl': user.photoURL ?? '',
        'provider': user.providerData.first.providerId,
        'createdAt': Timestamp.now(),
        'lastLoginAt': Timestamp.now(),
        'notifications': {
          'enabled': true,
          'taskReminders': true,
          'dailySummary': false,
        },
        'preferences': {'theme': 'system', 'defaultList': 'My Tasks'},
      });
    } else {
      await ref.update({'lastLoginAt': Timestamp.now()});
    }
  }
}
