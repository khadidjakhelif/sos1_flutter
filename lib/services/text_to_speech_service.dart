import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:stacked/stacked.dart';

class TextToSpeechService with ListenableServiceMixin {
  final FlutterTts _flutterTts = FlutterTts();
  
  final ReactiveValue<bool> _isSpeaking = ReactiveValue<bool>(false);
  
  bool get isSpeaking => _isSpeaking.value;
  
  Future<void> initialize() async {
    await _flutterTts.setLanguage('fr-FR');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setStartHandler(() {
      _isSpeaking.value = true;
      notifyListeners();
    });
    
    _flutterTts.setCompletionHandler(() {
      _isSpeaking.value = false;
      notifyListeners();
    });
    
    _flutterTts.setErrorHandler((error) {
      print('TTS Error: $error');
      _isSpeaking.value = false;
      notifyListeners();
    });
  }
  
  Future<void> speak(String text) async {
    if (_isSpeaking.value) {
      await stop();
    }
    await _flutterTts.speak(text);
  }
  
  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking.value = false;
    notifyListeners();
  }
  
  // Predefined emergency responses
  Future<void> speakGreeting() async {
    await speak('Bonjour, je suis votre assistant d\'urgence SOS1. Comment puis-je vous aider ?');
  }
  
  Future<void> speakListening() async {
    await speak('Je vous écoute');
  }
  
  Future<void> speakEmergencyDetected(EmergencyType type) async {
    String message;
    switch (type) {
      case EmergencyType.medical:
        message = 'Urgence médicale détectée. Je contacte le SAMU.';
        break;
      case EmergencyType.police:
        message = 'Urgence police détectée. Je contacte la police.';
        break;
      case EmergencyType.fire:
        message = 'Urgence incendie détectée. Je contacte les pompiers.';
        break;
    }
    await speak(message);
  }
  
  Future<void> speakHelpIsComing() async {
    await speak('L\'aide est en route. Restez calme.');
  }
  
  Future<void> speakNotUnderstood() async {
    await speak('Je n\'ai pas compris. Pouvez-vous répéter ?');
  }
  
  void dispose() {
    _flutterTts.stop();
  }
}

// Import from speech_recognition_service
enum EmergencyType {
  medical,
  police,
  fire,
}
