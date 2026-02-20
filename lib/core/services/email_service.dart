import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  // ⚠️ SECURITY WARNING: Storing credentials here is NOT secure for production.
  // Ideally, use a backend. For this demo, we use hardcoded credentials or user input.
  // Replace these with your credentials to test.
  static String? _username = "uupparaveeranji@gmail.com"; 
  static String? _password = "oioi zphy jhre ppsu"; 

  static void setCredentials(String email, String password) {
    _username = email;
    _password = password;
  }

  /// 📧 SEND REAL EMAIL
  static Future<void> sendEmail({
    required String toEmail,
    required String subject,
    required String body,
  }) async {
    if (_username == null || _password == null) {
      debugPrint("❌ [EmailService] Credentials not set!");
      return;
    }

    // 1. Configure SMTP Server (Gmail)
    final smtpServer = gmail(_username!, _password!);

    // 2. Create Message
    final message = Message()
      ..from = Address(_username!, 'Task Manager App')
      ..recipients.add(toEmail)
      ..subject = subject
      ..text = body;
      // ..html = "<h1>$body</h1>"; // Optional HTML

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      debugPrint('Message not sent.');
      for (var p in e.problems) {
        debugPrint('Problem: ${p.code}: ${p.msg}');
      }
      rethrow; // Re-throw to let BackgroundService know it failed
    }
  }

  // Deprecated: Scheduling is now handled by BackgroundService
  // static Future<void> scheduleEmail(...) {}
}
