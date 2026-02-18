import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  static Future<String> uploadProfilePhoto(XFile file) async {
    try {
      print("🚀 Starting uploadProfilePhoto...");
      final uid = _auth.currentUser!.uid;
      final ref = _storage.ref().child('users').child(uid).child('profile.jpg');

      if (kIsWeb) {
        print("💻 Running on Web. Reading bytes...");
        final bytes = await file.readAsBytes();
        print("✅ Bytes read: ${bytes.length}. Uploading to Storage...");
        
        final task = ref.putData(
            bytes, SettableMetadata(contentType: 'image/jpeg'));
        
        task.snapshotEvents.listen((event) {
          print("📸 Upload Progress: ${(event.bytesTransferred / event.totalBytes) * 100}%");
        });

        await task;
        print("✅ Upload complete.");
      } else {
        print("📱 Running on Mobile. Uploading file...");
        await ref.putFile(File(file.path));
        print("✅ File upload complete.");
      }

      print("🔗 Getting download URL...");
      final url = await ref.getDownloadURL();
      print("✅ Download URL retrieved: $url");
      return url;
    } catch (e) {
      print("❌ Error in uploadProfilePhoto: $e");
      rethrow;
    }
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
