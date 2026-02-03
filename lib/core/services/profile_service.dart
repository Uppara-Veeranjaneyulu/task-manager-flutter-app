import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  static Future<String> uploadProfilePhoto(File file) async {
    final uid = _auth.currentUser!.uid;

    final ref = _storage.ref().child('users').child(uid).child('profile.jpg');

    await ref.putFile(file);

    return await ref.getDownloadURL();
  }

  static Future<void> updateProfilePhoto(String url) async {
    final uid = _auth.currentUser!.uid;

    await _firestore.collection('users').doc(uid).update({'photoUrl': url});
  }

  /// ✏️ Update name in Firestore
  static Future<void> updateProfileName(String name) async {
    final uid = _auth.currentUser!.uid;

    await _firestore.collection('users').doc(uid).update({
      'name': name,
    });
  }
}
