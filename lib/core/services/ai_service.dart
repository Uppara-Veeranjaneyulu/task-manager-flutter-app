import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  GenerativeModel? _model;

  void _initIfNeeded() {
    if (_model != null) return;
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("GEMINI_API_KEY not found in .env");
    }
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
  }

  Future<String> askAboutTasks(String query, String uid) async {
    try {
      _initIfNeeded();

      // 1. Fetch tasks from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.docs.isEmpty) {
        return "You don't have any tasks yet! Please add some first.";
      }

      final tasks = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'title': data['title'] ?? 'Untitled',
            'status': (data['isCompleted'] ?? false) ? 'Completed' : 'Pending',
            'list': data['listName'] ?? 'General',
            'priority': data['priority'] ?? 'Medium',
          };
      }).toList();

      // 2. Build prompt
      final prompt = """
You are a helpful and intelligent AI Personal Assistant.
Here is the current task list for the user to help you provide context if they ask about their life or schedule:
${tasks.map((t) => "- ${t['title']} (${t['status']}, List: ${t['list']}, Priority: ${t['priority']})").join('\n')}

The user asked: "$query"

Guidelines:
1. If the user asks about their tasks, use the list above to provide specific answers.
2. If the user asks general questions (math, science, etc.), answer them accurately using your general knowledge.
3. If the user just wants to chat, be friendly and professional.
4. Keep the response concise but helpful.
""";

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content)
          .timeout(const Duration(seconds: 15));
      
      return response.text ?? "I'm sorry, I couldn't generate a response.";
    } catch (e) {
      return "Connectivity Error: ${e.toString()}";
    }
  }

  // 🧠 Static prediction logic for AddTaskScreen
  static String predictPriority(String title, String description) {
    String text = "$title $description".toLowerCase();
    if (text.contains('urgent') || text.contains('asap') || text.contains('immediately')) return 'High';
    if (text.contains('whenever') || text.contains('low') || text.contains('maybe')) return 'Low';
    return 'Medium';
  }

  static String suggestCategory(String title) {
    String t = title.toLowerCase();
    if (t.contains('buy') || t.contains('shop')) return 'Shopping';
    if (t.contains('call') || t.contains('meet')) return 'Work';
    if (t.contains('exercise') || t.contains('gym')) return 'Health';
    return 'General';
  }
}
