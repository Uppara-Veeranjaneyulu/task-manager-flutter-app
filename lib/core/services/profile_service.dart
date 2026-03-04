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

  static Future<String> uploadProfilePhoto(XFile file) async {
    try {
      print("🚀 Uploading to Vercel API...");
      final uid = _auth.currentUser!.uid;

      final bytes = await file.readAsBytes();
      print("📦 Image size: ${bytes.length} bytes");

      // Use our Vercel Serverless Function instead of direct Blob API
      // This is safer as the token is kept on the server
      final uri = Uri.parse('/api/upload-avatar?uid=$uid');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'image/jpeg',
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

      if (response.statusCode != 200) {
        throw Exception(
          'Upload failed (${response.statusCode}): ${response.body}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final url = json['url'] as String;
      print("✅ Upload success URL: $url");
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
