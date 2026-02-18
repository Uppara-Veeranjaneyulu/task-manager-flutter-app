// import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';

class VoiceService { // Singleton pattern
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  // final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  Future<bool> init() async {
    // try {
    //   _isAvailable = await _speech.initialize(
    //     onError: (val) => debugPrint('VoiceService onError: $val'),
    //     onStatus: (val) => debugPrint('VoiceService onStatus: $val'),
    //   );
    //   return _isAvailable;
    // } catch (e) {
    //   debugPrint('VoiceService Init Error: $e');
      return false;
    // }
  }

  Future<void> startListening({required Function(String) onResult}) async {
    // if (_isAvailable && !_speech.isListening) {
    //   await _speech.listen(
    //     onResult: (val) {
    //        if (val.recognizedWords.isNotEmpty) {
    //          onResult(val.recognizedWords);
    //        }
    //     },
    //     listenFor: const Duration(seconds: 30),
    //     pauseFor: const Duration(seconds: 5),
    //     partialResults: true,
    //   );
    // }
  }

  Future<void> stopListening() async {
    // if (_speech.isListening) {
    //   await _speech.stop();
    // }
  }
  
  bool get isListening => false; // _speech.isListening;
}
