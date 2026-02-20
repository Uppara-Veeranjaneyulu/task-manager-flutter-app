import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  //  Paste your BLOB_READ_WRITE_TOKEN from the Vercel Blob dashboard (.env.local tab)
  static const String _blobToken = 'vercel_blob_rw_VEa0SlcBWnJAt6aC_SMJ1np0INUW51Hf58rYOEo0lpy32Nx';

  static Future<String> uploadProfilePhoto(XFile file) async {
    try {
      print("🚀 Uploading to Vercel Blob...");
      final uid = _auth.currentUser!.uid;

      final bytes = await file.readAsBytes();
      print("📦 Image size: ${bytes.length} bytes");

      // Vercel Blob REST API — addRandomSuffix=0 keeps the same path on re-upload
      final uri = Uri.parse(
        'https://blob.vercel-storage.com/avatars/$uid/profile.jpg'
        '?addRandomSuffix=0',
      );

      final response = await http
          .put(
            uri,
            headers: {
              'Authorization': 'Bearer $_blobToken',
              'Content-Type': 'image/jpeg',
              'x-api-version': '7',
            },
            body: bytes,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception(
              'Upload timed out. Check your internet connection.',
            ),
          );

      print("📡 Response status: ${response.statusCode}");
      print("📡 Response body: ${response.body}");

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Vercel Blob upload failed (${response.statusCode}): ${response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final url = json['url'] as String;
      print("✅ Vercel Blob URL: $url");
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
    await _firestore.collection('users').doc(uid).update({'name': name});
  }
}
