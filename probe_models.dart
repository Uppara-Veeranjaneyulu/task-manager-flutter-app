import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  try {
    // Load .env
    await dotenv.load(fileName: ".env");
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      print("Error: GEMINI_API_KEY not found in .env");
      return;
    }

    print("Fetching models for API Key: ${apiKey.substring(0, 5)}...");

    // Basic model init to get a client (sdk might not have a direct listModels yet)
    // Actually, in some versions of the SDK, listModels is not exposed directly.
    // Let's check if we can reach it via a simple request or another model ID.
    
    print("Listing models is not directly supported in this version of the google_generative_ai SDK via a single method call.");
    print("However, we can try to probe common model IDs.");
    
    final modelsToProbe = [
      'gemini-1.5-flash',
      'gemini-1.5-flash-latest',
      'gemini-1.5-pro',
      'gemini-pro',
      'gemini-1.0-pro',
    ];

    for (var modelName in modelsToProbe) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        final content = [Content.text('hi')];
        await model.generateContent(content).timeout(Duration(seconds: 5));
        print("[AVAILABLE] $modelName");
      } catch (e) {
        if (e.toString().contains('404') || e.toString().contains('not found')) {
           print("[NOT FOUND] $modelName");
        } else {
           print("[ERROR] $modelName: $e");
        }
      }
    }
  } catch (e) {
    print("Script Error: $e");
  }
}
