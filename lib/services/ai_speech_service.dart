import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:stacked/stacked.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/language.dart';
import '../utils/app_config.dart';
import 'language_service.dart';
import 'package:audioplayers/audioplayers.dart';

/// AI-Powered Speech Recognition Service
/// Uses advanced NLP to detect emergency intents and extract key information
class AISpeechService with ListenableServiceMixin {
  final SpeechToText _speechToText = SpeechToText();
  final LanguageService _languageService;
  GenerativeModel? _geminiModel;
  
  final ReactiveValue<bool> _isListening = ReactiveValue<bool>(false);
  final ReactiveValue<bool> _isAvailable = ReactiveValue<bool>(false);
  final ReactiveValue<bool> _isProcessing = ReactiveValue<bool>(false);
  final ReactiveValue<String> _lastWords = ReactiveValue<String>('');
  final ReactiveValue<String> _recognizedWords = ReactiveValue<String>('');
  final ReactiveValue<EmergencyIntent?> _detectedIntent = ReactiveValue<EmergencyIntent?>(null);
  final ReactiveValue<double> _confidenceScore = ReactiveValue<double>(0.0);
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool get isListening => _isListening.value;
  bool get isAvailable => _isAvailable.value;
  bool get isProcessing => _isProcessing.value;
  String get lastWords => _lastWords.value;
  String get recognizedWords => _recognizedWords.value;
  EmergencyIntent? get detectedIntent => _detectedIntent.value;
  double get confidenceScore => _confidenceScore.value;

  StreamController<EmergencyIntent>? _intentStreamController;
  Stream<EmergencyIntent>? _intentStream;

  Stream<EmergencyIntent> get intentStream {
    _intentStreamController ??= StreamController<EmergencyIntent>.broadcast();
    _intentStream ??= _intentStreamController!.stream;
    return _intentStream!;
  }

  AISpeechService(this._languageService) {
    // Listen to language changes
    //_languageService.registerListener(_onLanguageChanged);
  }

  void _onLanguageChanged() {
    print('🌐 Language changed to: ${_languageService.currentLanguage.code}');
    notifyListeners();
  }

  String _getLocaleFromLanguage(AppLanguage language) {
    return language.locale;  // ✅ Uses your existing extension!
  }

  Future<void> initialize() async {
    print('🔊 Initializing speech...');

    try {
      _isAvailable.value = await _speechToText.initialize(
        onError: (error) {
          print('❌ Speech ERROR: $error');
        },
        onStatus: (status) {
          print('📡 Speech STATUS: $status');
          if (status == 'notListening') {
            _isListening.value = false;
            notifyListeners();
          }
        },
      );
      print('✅ Speech available: ${_isAvailable.value}');
    } catch (e) {
      print('💥 Speech init FAILED: $e');
    }
    //Initializing gemini model
    try {
      print('🤖 Initializing Gemini AI...');
      _geminiModel = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: AppConfig.geminiApiKey,
      );
      print('✅ Gemini AI initialized successfully');
    } catch (e) {
      print('❌ Gemini initialization error: $e');
    }

    notifyListeners();  // ← NO GEMINI
  }

  Future<void> playStartBeep() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/recording-start.mp3'));
    } catch (e) {
      print('Start beep error: $e');
    }
  }

  Future<void> playStopBeep() async {
    try {
      await _audioPlayer.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      await _audioPlayer.play(AssetSource('sounds/recording-end.mp3'));
    } catch (e) {
      print('Stop beep error: $e');
    }
  }

  Future<void> startListening() async {
    print('🎤 === START LISTENING ===');

    if (!_isAvailable.value) {
      print('⚠️  Not available, initializing...');
      await initialize();
      if (!_isAvailable.value) {
        print('❌ Cannot initialize speech');
        return;
      }
    }

    if (_isListening.value) {
      print('⏹️  Already listening, stopping first...');
      await stopListening();
      return;
    }

    _recognizedWords.value = '';
    _lastWords.value = '';
    _isListening.value = true;
    notifyListeners();

    // DYNAMIC LOCALE
    final localeId = _languageService.currentLanguage.locale;
    //final localeId = _getLocaleFromLanguage(_languageService.currentLanguage);
    print('👂 Listening in: $localeId (${_languageService.currentLanguage.displayName})');

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: localeId,  // ← DYNAMIC HERE
    );
  }

  Future<void> stopListening() async {
    print('🛑 === STOP LISTENING ===');
    _isListening.value = false;
    await _speechToText.stop();
    print('📝 Final words: "${_recognizedWords.value}"');
    notifyListeners();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords;
    final isFinal = result.finalResult;

    print('🗣️  Words: "$words" | Final: $isFinal');

    _lastWords.value = words;

    if (isFinal) {
      print('✅ FINAL RESULT: "$words"');
      _recognizedWords.value = words;
      _isListening.value = false;
      //Test
      print('🚀 Calling _processWithAI with text: "${result.recognizedWords}"');
      //
      _processWithAI(words);
      //Test
      print('📞 _processWithAI called');
    } else {
      print('⏳ PARTIAL: "$words"');
      //_detectEmergencyQuick(words);
    }

    notifyListeners();
  }

  /// Quick emergency detection for immediate response
  void _detectEmergencyQuick(String text) {
    final lowerText = text.toLowerCase();
    
    // Fast keyword matching
    final keywords = {
      'cardiac': ['coeur', 'cardiaque', 'poitrine', 'douleur thoracique', 'infarctus'],
      'bleeding': ['saigne', 'saignement', 'hémorragie', 'sang', 'coupé'],
      'choking': ['étouffe', 'étouffement', 'ne peut pas respirer', 'gorge'],
      'unconscious': ['inconscient', 'évanoui', 'ne répond pas', 'coma'],
      'breathing': ['respire pas', 'difficulté à respirer', 'essoufflement'],
      'fire': ['feu', 'incendie', 'brûle', 'flamme'],
      'police': ['police', 'vol', 'agression', 'cambriolage', 'danger'],
    };
    
    for (final entry in keywords.entries) {
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          _detectedIntent.value = EmergencyIntent(
            type: entry.key,
            confidence: 0.7,
            rawText: text,
            isQuickDetection: true,
          );
          _confidenceScore.value = 0.7;
          notifyListeners();
          return;
        }
      }
    }
  }

  /// AI-powered emergency detection using Gemini
  Future<void> _processWithAI(String text) async {
    print('🤖 ========== _processWithAI STARTED ==========');
    print('📝 Input text: "$text"');
    if (_geminiModel == null) {
      // Fallback to keyword detection
      print('⚠️ Gemini model is null, using fallback');
      _detectEmergencyQuick(text);
      return;
    }

    print('✅ Gemini model exists, proceeding...');

    _isProcessing.value = true;
    notifyListeners();
    
    try {
      final prompt = '''
Analyse ce message d'urgence et identifie:
1. Le type d'urgence (medical, police, fire, cardiac, bleeding, choking, unconscious, other)
2. Le niveau de gravité (1-10)
3. Les mots-clés détectés
4. Une brève description

Message: "$text"

Réponds UNIQUEMENT en JSON:
{
  "type": "type_d_urgence",
  "severity": 8,
  "keywords": ["mot1", "mot2"],
  "description": "description courte",
  "needsImmediateResponse": true/false
}
''';final response = await _geminiModel!.generateContent([Content.text(prompt)]);
      final responseText = response.text;
      
      if (responseText != null) {
        // Parse AI response
        final intent = _parseAIResponse(responseText, text);
        _detectedIntent.value = intent;
        _confidenceScore.value = intent.confidence;
        _intentStreamController?.add(intent);
      }
    } catch (e) {
      print('AI processing error: $e');
      // Fallback to keyword detection
      _detectEmergencyQuick(text);
    }
    
    _isProcessing.value = false;
    notifyListeners();
  }

  EmergencyIntent _parseAIResponse(String aiResponse, String originalText) {
    try {
      print('🔍 Parsing AI response...');
      print('Raw response length: ${aiResponse.length} characters');

      // Extract JSON from response (handle markdown code blocks)
      String jsonStr = aiResponse;

      if (aiResponse.contains('```json')) {
        print('📦 Found JSON markdown block with "```json"');
        jsonStr = aiResponse.split('```json')[1].split('```')[0];
        print('Extracted JSON: $jsonStr');
      } else if (aiResponse.contains('```')) {
        print('📦 Found generic markdown block with "```"');
        jsonStr = aiResponse.split('```')[1].split('```')[0];
        print('Extracted JSON: $jsonStr');
      } else {
        print('📄 No markdown blocks found, using raw response');
      }

      // Simple parsing (in production, use proper JSON parsing)
      final type = _extractValue(jsonStr, '"type"');
      final severityStr = _extractValue(jsonStr, '"severity"');
      final severity = int.tryParse(severityStr ?? '') ?? 5;
      final needsImmediate = jsonStr.contains('"needsImmediateResponse": true');

      print('📊 Extracted values:');
      print('   type: $type');
      print('   severity string: $severityStr');
      print('   severity int: $severity');
      print('   needsImmediate: $needsImmediate');

      final intent = EmergencyIntent(
        type: type ?? 'unknown',
        confidence: severity / 10.0,
        rawText: originalText,
        severity: severity,
        needsImmediateResponse: needsImmediate,
        isQuickDetection: false,
      );

      print('✅ Successfully created EmergencyIntent');
      return intent;

    } catch (e) {
      print('❌ Parsing error: $e');
      print('Stack trace: ${StackTrace.current}');

      return EmergencyIntent(
        type: 'unknown',
        confidence: 0.5,
        rawText: originalText,
      );
    }
  }

  String? _extractValue(String json, String key) {
    print('🔎 Extracting key: $key from JSON');

    final pattern = '$key\\s*:\\s*"([^"]+)"';
    final regex = RegExp(pattern);
    final match = regex.firstMatch(json);

    final value = match?.group(1);
    print('   Result: $value');

    return value;
  }

  void clearRecognizedWords() {
    _recognizedWords.value = '';
    _lastWords.value = '';
    _detectedIntent.value = null;
    _confidenceScore.value = 0.0;
    notifyListeners();
  }

  void dispose() {
    _intentStreamController?.close();
    _speechToText.cancel();
  }
}

/// Emergency Intent Model
class EmergencyIntent {
  final String type;
  final double confidence;
  final String rawText;
  final int? severity;
  final bool? needsImmediateResponse;
  final bool isQuickDetection;
  final DateTime timestamp;

  EmergencyIntent({
    required this.type,
    required this.confidence,
    required this.rawText,
    this.severity,
    this.needsImmediateResponse,
    this.isQuickDetection = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isHighConfidence => confidence >= 0.7;
  bool get isMediumConfidence => confidence >= 0.4 && confidence < 0.7;
  bool get isLowConfidence => confidence < 0.4;

  String get displayType {
    final types = {
      'cardiac': 'Urgence Cardiaque',
      'bleeding': 'Saignement',
      'choking': 'Étouffement',
      'unconscious': 'Inconscience',
      'breathing': 'Difficulté Respiratoire',
      'fire': 'Incendie',
      'police': 'Urgence Police',
      'medical': 'Urgence Médicale',
      'other': 'Autre Urgence',
    };
    return types[type.toLowerCase()] ?? 'Urgence';
  }
}
