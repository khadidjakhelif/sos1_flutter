import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:stacked/stacked.dart';
import '../utils/app_config.dart';


/// AI-Powered Text-to-Speech Service
/// Uses advanced TTS with natural voice synthesis for emergency guidance
class AITtsService with ListenableServiceMixin {
  final FlutterTts _flutterTts = FlutterTts();
  GenerativeModel? _chatModel;
  
  final ReactiveValue<bool> _isSpeaking = ReactiveValue<bool>(false);
  final ReactiveValue<bool> _isProcessing = ReactiveValue<bool>(false);
  final ReactiveValue<String> _currentMessage = ReactiveValue<String>('');
  
  bool get isSpeaking => _isSpeaking.value;
  bool get isProcessing => _isProcessing.value;
  String get currentMessage => _currentMessage.value;

  // AI TTS Configuration
  double _speechRate = 0.45; // Slower for emergencies
  double _pitch = 1.0;
  double _volume = 1.0;
  
  // Queue for sequential speech
  final List<String> _speechQueue = [];
  bool _isQueueProcessing = false;

  Future<void> initialize() async {
    await _flutterTts.setLanguage('fr-FR');
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(_pitch);
    
    // Set up handlers
    _flutterTts.setStartHandler(() {
      _isSpeaking.value = true;
      notifyListeners();
    });
    
    _flutterTts.setCompletionHandler(() {
      _isSpeaking.value = false;
      notifyListeners();
      _processSpeechQueue();
    });
    
    _flutterTts.setErrorHandler((error) {
      print('TTS Error: $error');
      _isSpeaking.value = false;
      _isProcessing.value = false;
      notifyListeners();
    });

    try {
      _chatModel = GenerativeModel(
        model: 'gemini-2.5-flash',  // ← Updated model
        apiKey: AppConfig.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 500,
        ),
      );
    } catch (e) {
      print('Gemini initialization error: $e');
    }
  }

  /// Speak with AI-enhanced natural voice
  Future<void> speak(String text, {bool urgent = false}) async {
    if (text.isEmpty) return;
    
    _currentMessage.value = text;
    
    // Adjust speech rate based on urgency
    if (urgent) {
      await _flutterTts.setSpeechRate(0.55);
    } else {
      await _flutterTts.setSpeechRate(_speechRate);
    }
    
    await _flutterTts.speak(text);
  }

  /// Queue multiple messages for sequential playback
  Future<void> speakSequence(List<String> messages, {bool urgent = false}) async {
    _speechQueue.addAll(messages);
    if (!_isQueueProcessing) {
      _processSpeechQueue(urgent: urgent);
    }
  }

  void _processSpeechQueue({bool urgent = false}) async {
    if (_speechQueue.isEmpty) {
      _isQueueProcessing = false;
      return;
    }
    
    _isQueueProcessing = true;
    final message = _speechQueue.removeAt(0);
    await speak(message, urgent: urgent);
  }

  /// AI-powered emergency guidance with step-by-step instructions
  Future<void> speakEmergencyGuidance(EmergencyProtocol protocol) async {
    final steps = protocol.steps;
    
    // Introduction
    await speak(
      "Urgence détectée: ${protocol.name}. Je vais vous guider étape par étape.",
      urgent: true,
    );
    
    // Wait for intro to complete
    await Future.delayed(const Duration(seconds: 3));
    
    // Speak each step with pauses
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      await speak(
        "Étape ${i + 1}: $step",
        urgent: true,
      );
      
      // Wait for user acknowledgment or time-based progression
      await Future.delayed(const Duration(seconds: 5));
    }
    
    // Conclusion
    await speak(
      "Les secours ont été alertés. Restez calme et suivez les instructions.",
      urgent: true,
    );
  }

  /// Generate AI-enhanced emergency response using Gemini API
  Future<String> generateEmergencyResponse({
    required String emergencyType,
    required String userMessage,
    String? location,
  }) async {
    _isProcessing.value = true;
    notifyListeners();

    try {
      if (_chatModel == null) {
        print('Gemini model not initialized, using fallback');
        _isProcessing.value = false;
        notifyListeners();
        return _getFallbackResponse(emergencyType);
      }

      final prompt = _buildEmergencyPrompt(
        emergencyType: emergencyType,
        userMessage: userMessage,
        location: location,
      );

      // ✅ Use the SDK (already configured correctly)
      final response = await _chatModel!.generateContent([Content.text(prompt)]);
      final generatedText = response.text;

      _isProcessing.value = false;
      notifyListeners();

      return generatedText ?? _getFallbackResponse(emergencyType);
    } catch (e) {
      print('AI TTS Error: $e');
      _isProcessing.value = false;
      notifyListeners();
      return _getFallbackResponse(emergencyType);
    }
  }

  String _buildEmergencyPrompt({
    required String emergencyType,
    required String userMessage,
    String? location,
  }) {
    return '''
Tu es un assistant d'urgence médicale professionnel pour SOS Algérie. 
L'utilisateur a signalé une urgence de type: $emergencyType.
Message de l'utilisateur: "$userMessage"
${location != null ? 'Localisation: $location' : ''}

Fournis une réponse CONCISE et RASSURANTE en français (2-3 phrases maximum) qui:
1. Confirme la compréhension de l'urgence
2. Donne une première instruction immédiate et simple
3. Rassure l'utilisateur que l'aide est en route

Réponds UNIQUEMENT avec le message à dire, sans introduction.
''';}

  String _getFallbackResponse(String emergencyType) {
    final responses = {
      'cardiac': 'Arrêt cardiaque détecté. Commencez les compressions thoraciques immédiatement. Les secours sont en route.',
      'bleeding': 'Saignement détecté. Appliquez une pression directe sur la plaie. Gardez la personne allongée.',
      'choking': 'Étouffement détecté. Encouragez la toux si possible. Les secours arrivent.',
      'medical': 'Urgence médicale détectée. Restez calme, ne déplacez pas la victime. Les secours sont alertés.',
      'fire': 'Incendie détecté. Évacuez immédiatement le bâtiment. Ne prenez pas l\'ascenseur.',
      'police': 'Urgence sécurité détectée. Mettez-vous en sécurité. La police est alertée.',
    };
    
    return responses[emergencyType.toLowerCase()] ?? 
           'Urgence détectée. Restez calme, les secours sont en route.';
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _speechQueue.clear();
    _isSpeaking.value = false;
    _isQueueProcessing = false;
    notifyListeners();
  }

  void dispose() {
    _flutterTts.stop();
    _speechQueue.clear();
  }
}

/// Emergency Protocol Model
class EmergencyProtocol {
  final String id;
  final String name;
  final String description;
  final List<String> steps;
  final String emergencyNumber;
  final Duration estimatedResponseTime;

  EmergencyProtocol({
    required this.id,
    required this.name,
    required this.description,
    required this.steps,
    required this.emergencyNumber,
    this.estimatedResponseTime = const Duration(minutes: 10),
  });
}

/// Predefined Emergency Protocols
class EmergencyProtocols {
  static EmergencyProtocol get cardiacArrest => EmergencyProtocol(
    id: 'cardiac_arrest',
    name: 'Arrêt Cardiaque',
    description: 'Protocole de réanimation cardiopulmonaire',
    emergencyNumber: '15',
    steps: [
      'Vérifiez la conscience de la victime en la secouant doucement.',
      'Appelez les secours au 15 ou demandez à quelqu\'un de le faire.',
      'Commencez les compressions thoraciques: 100 à 120 par minute.',
      'Poussez fort et vite au milieu de la poitrine, sur le sternum.',
      'Alternez 30 compressions avec 2 insufflations si entraîné.',
      'Continuez jusqu\'à l\'arrivée des secours ou de l\'AED.',
    ],
  );

  static EmergencyProtocol get severeBleeding => EmergencyProtocol(
    id: 'severe_bleeding',
    name: 'Saignement Sévère',
    description: 'Contrôle d\'un saignement important',
    emergencyNumber: '15',
    steps: [
      'Appliquez une pression directe sur la plaie avec un tissu propre.',
      'Maintenez la pression sans relâcher pendant au moins 10 minutes.',
      'Si possible, surélevez la partie blessée au-dessus du cœur.',
      'Ne retirez pas le tissu si il est imbibé de sang, ajoutez-en par-dessus.',
      'Gardez la personne allongée et couverte pour éviter le choc.',
      'Surveillez la respiration et la conscience en attendant les secours.',
    ],
  );

  static EmergencyProtocol get choking => EmergencyProtocol(
    id: 'choking',
    name: 'Étouffement',
    description: 'Manière de Heimlich et premiers secours',
    emergencyNumber: '15',
    steps: [
      'Encouragez la personne à tousser si elle peut encore respirer.',
      'Si la toux est inefficace, placez-vous derrière la personne.',
      'Enlacez-la au niveau de la taille avec vos bras.',
      'Fermez votre poing et placez-le entre le nombril et le sternum.',
      'Saisissez votre poing avec l\'autre main et tirez vers l\'intérieur et vers le haut.',
      'Répétez jusqu\'à ce que l\'objet soit expulsé.',
    ],
  );

  static EmergencyProtocol get burn => EmergencyProtocol(
    id: 'burn',
    name: 'Brûlure',
    description: 'Premiers soins pour brûlures',
    emergencyNumber: '15',
    steps: [
      'Refroidissez la brûlure sous l\'eau froide courante pendant 20 minutes.',
      'Retirez les bijoux et vêtements lâches avant que l\'enflure commence.',
      'Ne retirez pas les vêtements collés à la peau.',
      'Ne mettez pas de glace directement sur la brûlure.',
      'Couvrez la brûlure avec un film plastique propre ou un pansement stérile.',
      'Ne percez pas les cloques si elles se forment.',
    ],
  );

  static EmergencyProtocol? getProtocol(String emergencyType) {
    final protocols = {
      'cardiac': cardiacArrest,
      'heart': cardiacArrest,
      'crise cardiaque': cardiacArrest,
      'arrêt cardiaque': cardiacArrest,
      'bleeding': severeBleeding,
      'saignement': severeBleeding,
      'hémorragie': severeBleeding,
      'choking': choking,
      'étouffement': choking,
      'burn': burn,
      'brûlure': burn,
    };
    
    return protocols[emergencyType.toLowerCase()];
  }
}

// Import from speech_recognition_service
enum EmergencyType {
  medical,
  police,
  fire,
}
