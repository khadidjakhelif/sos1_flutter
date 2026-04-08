import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:stacked/stacked.dart';

class SpeechRecognitionService with ListenableServiceMixin {
  final SpeechToText _speechToText = SpeechToText();
  
  final ReactiveValue<bool> _isListening = ReactiveValue<bool>(false);
  final ReactiveValue<bool> _isAvailable = ReactiveValue<bool>(false);
  final ReactiveValue<String> _lastWords = ReactiveValue<String>('');
  final ReactiveValue<String> _recognizedWords = ReactiveValue<String>('');
  
  bool get isListening => _isListening.value;
  bool get isAvailable => _isAvailable.value;
  String get lastWords => _lastWords.value;
  String get recognizedWords => _recognizedWords.value;
  
  StreamController<String>? _wordsStreamController;
  Stream<String>? _wordsStream;
  
  Stream<String> get wordsStream {
    _wordsStreamController ??= StreamController<String>.broadcast();
    _wordsStream ??= _wordsStreamController!.stream;
    return _wordsStream!;
  }
  
  Future<bool> initialize() async {
    try {
      _isAvailable.value = await _speechToText.initialize(
        onError: (error) => print('Speech error: $error'),
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'notListening') {
            _isListening.value = false;
            notifyListeners();
          }
        },
      );
      notifyListeners();
      return _isAvailable.value;
    } catch (e) {
      print('Speech initialization error: $e');
      return false;
    }
  }
  
  Future<void> startListening() async {
    if (!_isAvailable.value) {
      final initialized = await initialize();
      if (!initialized) return;
    }
    
    if (_isListening.value) {
      await stopListening();
      return;
    }
    
    _recognizedWords.value = '';
    _isListening.value = true;
    notifyListeners();
    
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      localeId: 'fr_FR',
      onSoundLevelChange: (level) {
        // Can be used for visual feedback
      },
    );
  }
  
  Future<void> stopListening() async {
    _isListening.value = false;
    await _speechToText.stop();
    notifyListeners();
  }
  
  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords.value = result.recognizedWords;
    
    if (result.finalResult) {
      _recognizedWords.value = result.recognizedWords;
      _wordsStreamController?.add(result.recognizedWords);
    }
    
    notifyListeners();
  }
  
  void clearRecognizedWords() {
    _recognizedWords.value = '';
    _lastWords.value = '';
    notifyListeners();
  }
  
  // Emergency detection logic
  EmergencyType? detectEmergency(String text) {
    final lowerText = text.toLowerCase();
    
    // Medical keywords
    final medicalKeywords = [
      'ambulance', 'médical', 'médecin', 'blessé', 'douleur', 
      'crise cardiaque', 'inconscient', 'saignement', 'urgence médicale',
      'samu', 'hôpital', 'malaise', 'respiration', 'accident'
    ];
    
    // Police keywords
    final policeKeywords = [
      'police', 'vol', 'agression', 'cambriolage', 'danger',
      'menace', 'agresseur', 'voleur', 'urgence police', 'gendarmerie'
    ];
    
    // Fire keywords
    final fireKeywords = [
      'feu', 'incendie', 'pompier', 'fumée', 'brûlure',
      'explosion', 'urgence incendie', 'flammes'
    ];
    
    for (final keyword in medicalKeywords) {
      if (lowerText.contains(keyword)) return EmergencyType.medical;
    }
    
    for (final keyword in policeKeywords) {
      if (lowerText.contains(keyword)) return EmergencyType.police;
    }
    
    for (final keyword in fireKeywords) {
      if (lowerText.contains(keyword)) return EmergencyType.fire;
    }
    
    return null;
  }
  
  void dispose() {
    _wordsStreamController?.close();
    _speechToText.cancel();
  }
}

enum EmergencyType {
  medical,
  police,
  fire,
}

extension EmergencyTypeExtension on EmergencyType {
  String get displayName {
    switch (this) {
      case EmergencyType.medical:
        return 'Urgence Médicale';
      case EmergencyType.police:
        return 'Urgence Police';
      case EmergencyType.fire:
        return 'Urgence Incendie';
    }
  }
  
  String get phoneNumber {
    switch (this) {
      case EmergencyType.medical:
        return '15'; // SAMU France
      case EmergencyType.police:
        return '17'; // Police France
      case EmergencyType.fire:
        return '18'; // Pompiers France
    }
  }
}
