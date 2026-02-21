import 'dart:io';
import 'dart:convert';

void main() async {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('Error: .env file not found');
    return;
  }

  final lines = envFile.readAsLinesSync();
  String? apiKey;
  for (var line in lines) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }

  if (apiKey == null || apiKey.isEmpty) {
    print('Error: GEMINI_API_KEY not found in .env');
    return;
  }

  print('Fetching available models from Gemini API...');
  
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  
  final client = HttpClient();
  try {
    final request = await client.getUrl(url);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      final models = data['models'] as List;
      print('\nAvailable Models:');
      print('-----------------');
      for (var model in models) {
        print(model['name']);
      }
    } else {
      print('Error: ${response.statusCode}');
      print('Response: $responseBody');
    }
  } catch (e) {
    print('Request Error: $e');
  } finally {
    client.close();
  }
}
