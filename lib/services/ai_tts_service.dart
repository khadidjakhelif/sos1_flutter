import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:stacked/stacked.dart';
import '../app/app.locator.dart';
import '../utils/app_config.dart';
import '../services/ai_provider_service.dart';
import 'language_service.dart';

/// AI-Powered Text-to-Speech Service
/// Uses advanced TTS with natural voice synthesis for emergency guidance
class AITtsService with ListenableServiceMixin {
  final FlutterTts _flutterTts = FlutterTts();

  final AIProviderService _aiProvider = AIProviderService();

  LanguageService? _languageService;

  final ReactiveValue<bool> _isSpeaking = ReactiveValue<bool>(false);
  final ReactiveValue<bool> _isProcessing = ReactiveValue<bool>(false);
  final ReactiveValue<String> _currentMessage = ReactiveValue<String>('');

  bool get isSpeaking => _isSpeaking.value;
  bool get isProcessing => _isProcessing.value;
  String get currentMessage => _currentMessage.value;

  double _speechRate = 0.45;
  double _pitch = 1.0;
  double _volume = 1.0;

  final List<String> _speechQueue = [];
  bool _isQueueProcessing = false;

  AITtsService([this._languageService]);

  Future<void> initialize() async {
    await _setupTtsLanguage();

    _languageService?.addListener(() {
      _setupTtsLanguage();
    });

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
      await _aiProvider.initialize();
      print('✅ [AITtsService] Provider: ${_aiProvider.providerName}');
    } catch (e) {
      print('Gemini initialization error: $e');
    }
  }

  Future<void> _setupTtsLanguage() async {
    final langCode = _languageService?.getLanguageCode() ?? 'fr';

    print('🔍 _languageService is null: ${_languageService == null}');
    print('🔍 langCode: ${_languageService?.getLanguageCode()}');

    const localeMap = {
      'fr': 'fr-FR',
      'ar': 'ar',       // exactly as returned by getLanguages()
      'en': 'en-US',
    };

    final locale = localeMap[langCode] ?? 'fr-FR';
    print('🔊 Setting TTS locale: $locale');

    // Set language FIRST, then voice settings — order matters on Android
    await _flutterTts.setLanguage(locale);
    if (langCode == 'en') {
      // Force a specific English voice to override system default
      await _flutterTts.setVoice({'name': 'en-us-x-sfg#male_1-local', 'locale': 'en-US'});
    }
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(_pitch);

    // Force the engine to commit the language change before speaking
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> speak(String text, {bool urgent = false}) async {
    if (text.isEmpty) return;

    // Stop anything currently playing before changing language
    await _flutterTts.stop();

    _currentMessage.value = text;

    // Apply language fresh before every utterance — Android TTS resets between calls
    await _setupTtsLanguage();

    await _flutterTts.setSpeechRate(urgent ? 0.55 : _speechRate);
    await _flutterTts.speak(text);
  }

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

  /// Protocol speech — UNCHANGED
  Future<void> speakEmergencyGuidance(EmergencyProtocol protocol) async {
    final steps = protocol.steps;
    await speak(
      "Urgence détectée: ${protocol.name}. Je vais vous guider étape par étape.",
      urgent: true,
    );
    await Future.delayed(const Duration(seconds: 3));
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      await speak("Étape ${i + 1}: $step", urgent: true);
      await Future.delayed(const Duration(seconds: 5));
    }
    await speak(
      "Les secours ont été alertés. Restez calme et suivez les instructions.",
      urgent: true,
    );
  }

  /// Generate AI emergency response
  /// CHANGED: _chatModel!.generateContent → _aiProvider.generateContent
  Future<String> generateEmergencyResponse({
    required String emergencyType,
    required String userMessage,
    String? location,
    String? languageCode,
  }) async {
    _isProcessing.value = true;
    notifyListeners();

    final lang = languageCode ?? _languageService?.getLanguageCode() ?? 'fr';

    try {
      final prompt = _buildEmergencyPrompt(
        emergencyType: emergencyType,
        userMessage: userMessage,
        location: location,
        languageCode: lang,
      );

      // CHANGED: was _chatModel!.generateContent([Content.text(prompt)])
      final generatedText = await _aiProvider.generateContent(prompt);

      _isProcessing.value = false;
      notifyListeners();
      return generatedText ?? _getFallbackResponse(emergencyType, lang);
    } catch (e) {
      print('AI TTS Error: $e');
      _isProcessing.value = false;
      notifyListeners();
      return _getFallbackResponse(emergencyType, lang);
    }
  }

  /// UNCHANGED
  String _buildEmergencyPrompt({
    required String emergencyType,
    required String userMessage,
    String? location,
    required String languageCode,
  }) {
    final langPrefix = {
      'fr': 'Tu es un assistant d\'urgence en français pour SOS Algérie.',
      'ar': 'أنت مساعد طوارئ بالعربية لـ SOS الجزائر.',
      'en': 'You are an emergency assistant in English for SOS Algeria.',
    }[languageCode] ?? 'Tu es un assistant d\'urgence pour SOS Algérie.';

    final langInstruction = {
      'fr': 'Réponds en français (2-3 phrases max)',
      'ar': 'أجب بالعربية (2-3 جمل كحد أقصى)',
      'en': 'Respond in English (2-3 sentences max)',
    }[languageCode] ?? 'Réponds en français (2-3 phrases max)';

    return '''
$langPrefix
$langInstruction

Urgence: $emergencyType
Message: "$userMessage"
${location != null ? 'Localisation: $location' : ''}

1. Confirme la compréhension
2. Instruction IMMÉDIATE simple  
3. Rassure l\'utilisateur

Réponds UNIQUEMENT avec le message à dire.
''';
  }

  /// UNCHANGED except now multilingual
  String _getFallbackResponse(String emergencyType, String langCode) {
    final responses = {
      'fr': {
        'cardiac': 'Arrêt cardiaque détecté. Commencez les compressions thoraciques immédiatement. Les secours sont en route.',
        'bleeding': 'Saignement détecté. Appliquez une pression directe sur la plaie. Gardez la personne allongée.',
        'choking': 'Étouffement détecté. Encouragez la toux si possible. Les secours arrivent.',
        'medical': 'Urgence médicale détectée. Restez calme, ne déplacez pas la victime. Les secours sont alertés.',
        'fire': 'Incendie détecté. Évacuez immédiatement le bâtiment. Ne prenez pas l\'ascenseur.',
        'police': 'Urgence sécurité détectée. Mettez-vous en sécurité. La police est alertée.',
      },
      'ar': {
        'cardiac': 'توقف قلبي. ابدأ ضغطات الصدر فوراً. المساعدة في الطريق.',
        'bleeding': 'نزيف. اضغط على الجرح مباشرة. أبقِ الشخص مستلقياً.',
        'choking': 'اختناق. شجع السعال إن أمكن. المساعدة قادمة.',
        'medical': 'طوارئ طبية. اهدأ، لا تحرك الضحية. تم تنبيه المساعدة.',
        'fire': 'حريق. اخرج فوراً. لا تستخدم المصعد.',
        'police': 'طوارئ أمنية. تأمن. الشرطة في الطريق.',
      },
      'en': {
        'cardiac': 'Cardiac arrest detected. Start chest compressions immediately. Help is on the way.',
        'bleeding': 'Bleeding detected. Apply direct pressure to the wound. Keep the person lying down.',
        'choking': 'Choking detected. Encourage coughing if possible. Help is coming.',
        'medical': 'Medical emergency detected. Stay calm, do not move the victim. Help has been alerted.',
        'fire': 'Fire detected. Evacuate the building immediately. Do not use the elevator.',
        'police': 'Security emergency detected. Get to safety. Police have been alerted.',
      },
    };
    return responses[langCode]?[emergencyType.toLowerCase()]
        ?? responses['fr']![emergencyType.toLowerCase()]
        ?? 'Urgence détectée. Restez calme, les secours sont en route.';
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

/// Emergency Protocol Model — UNCHANGED
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

/// Predefined Emergency Protocols — taken from document 27 as-is
class EmergencyProtocols {
  static EmergencyProtocol getProtocol(String emergencyType) {
    final langCode = locator<LanguageService>().getLanguageCode();
    final lowerType = emergencyType.toLowerCase().trim();

    switch (lowerType) {
      case 'cardiac':
      case 'crise cardiaque':
      case 'arrêt cardiaque':
      case 'توقف قلبي':
      case 'heart':
      case 'heart attack':
        return cardiacArrest(langCode);
      case 'bleeding':
      case 'saignement':
      case 'hémorragie':
      case 'نزيف':
        return severeBleeding(langCode);
      case 'choking':
      case 'étouffement':
      case 'اختناق':
        return choking(langCode);
      case 'fire':
      case 'incendie':
      case 'حريق':
        return fire(langCode);
      case 'police':
      case 'security':
        return policeEmergency(langCode);
      case 'burn':
      case 'brûlure':
        return burn(langCode);
      default:
        return medicalEmergency(langCode);
    }
  }

  static EmergencyProtocol cardiacArrest(String langCode) {
    switch (langCode) {
      case 'fr':
        return EmergencyProtocol(
          id: 'cardiac_arrest', name: 'Arrêt Cardiaque',
          description: 'Réanimation Cardio-Pulmonaire (RCP)',
          steps: ['Vérifiez conscience: secouez + parlez fort.', 'Appelez 15 immédiatement.', 'Mains centre sternum.', '100-120 compressions/min (Stayin\' Alive).', 'Poussez 5-6cm, relâchez complètement.', 'Continuez jusqu\'aux secours.'],
          emergencyNumber: '15',
        );
      case 'ar':
        return EmergencyProtocol(
          id: 'cardiac_arrest', name: 'توقف القلب',
          description: 'إنعاش قلبي رئوي',
          steps: ['تحقق الوعي: هز + صوت عال.', 'اتصل بـ 15 فوراً.', 'اليدين وسط الصدر.', '100-120 ضغطة/دقيقة.', 'اضغط 5-6سم، أفلت تماماً.', 'استمر حتى الإسعاف.'],
          emergencyNumber: '15',
        );
      case 'en':
        return EmergencyProtocol(
          id: 'cardiac_arrest', name: 'Cardiac Arrest',
          description: 'Cardiopulmonary Resuscitation (CPR)',
          steps: ['Check consciousness: shake + speak loud.', 'Call 15 immediately.', 'Hands center sternum.', '100-120 compressions/min.', 'Push 5-6cm, release fully.', 'Continue until help.'],
          emergencyNumber: '15',
        );
      default:
        return cardiacArrest('fr');
    }
  }

  static EmergencyProtocol severeBleeding(String langCode) {
    switch (langCode) {
      case 'fr':
        return EmergencyProtocol(
          id: 'severe_bleeding', name: 'Saignement Sévère',
          description: 'Contrôle hémorragie',
          steps: ['Pression DIRECTE plaie (10+ min).', 'Surélevez > cœur.', 'Ajoutez tissus si saturé.', 'Gardez CHAUDE + ALLONGÉE.', 'NE retirez PAS objets.'],
          emergencyNumber: '15',
        );
      case 'ar':
        return EmergencyProtocol(
          id: 'severe_bleeding', name: 'نزيف شديد',
          description: 'التحكم في النزيف',
          steps: ['ضغط مباشر على الجرح.', 'ارفع فوق القلب.', 'أضف قماش إذا امتلأ.', 'دفء + مستلقي.', 'لا تسحب أجسام.'],
          emergencyNumber: '15',
        );
      case 'en':
        return EmergencyProtocol(
          id: 'severe_bleeding', name: 'Severe Bleeding',
          description: 'Hemorrhage control',
          steps: ['DIRECT wound pressure.', 'Elevate > heart.', 'Add cloth if soaked.', 'Keep WARM + DOWN.', 'NO object removal.'],
          emergencyNumber: '15',
        );
      default:
        return severeBleeding('fr');
    }
  }

  static EmergencyProtocol choking(String langCode) {
    switch (langCode) {
      case 'fr':
        return EmergencyProtocol(
          id: 'choking', name: 'Étouffement',
          description: 'Manœuvre Heimlich',
          steps: ['Encouragez TOUX.', '5 claques omoplates.', '5 compressions abdominales.', 'Répétez jusqu\'expulsion.', 'RCP si inconscience.'],
          emergencyNumber: '15',
        );
      case 'ar':
        return EmergencyProtocol(
          id: 'choking', name: 'اختناق',
          description: 'مناورة هيمليك',
          steps: ['شجع السعال.', '5 ضربات الكتف.', '5 ضغطات بطن.', 'كرر حتى الإخراج.', 'RCP إذا فقد وعي.'],
          emergencyNumber: '15',
        );
      case 'en':
        return EmergencyProtocol(
          id: 'choking', name: 'Choking',
          description: 'Heimlich maneuver',
          steps: ['Encourage COUGH.', '5 back blows.', '5 abdominal thrusts.', 'Repeat until clear.', 'CPR if unconscious.'],
          emergencyNumber: '15',
        );
      default:
        return choking('fr');
    }
  }

  static EmergencyProtocol fire(String langCode) {
    switch (langCode) {
      case 'fr':
        return EmergencyProtocol(
          id: 'fire', name: 'Incendie',
          description: 'Évacuation',
          steps: ['ÉVACUEZ par escaliers.', 'ASCENSEUR INTERDIT.', 'Fermez PORTES.', 'Appelez 14.', 'BAS si fumée.'],
          emergencyNumber: '14',
        );
      case 'ar':
        return EmergencyProtocol(
          id: 'fire', name: 'حريق',
          description: 'إخلاء',
          steps: ['أخلُ بالدرج.', 'المصعد ممنوع.', 'أغلق الأبواب.', 'اتصل بـ 14.', 'انخفض إذا دخان.'],
          emergencyNumber: '14',
        );
      case 'en':
        return EmergencyProtocol(
          id: 'fire', name: 'Fire',
          description: 'Evacuation',
          steps: ['EVACUATE stairs.', 'NO elevator.', 'Close DOORS.', 'Call 14.', 'LOW if smoke.'],
          emergencyNumber: '14',
        );
      default:
        return fire('fr');
    }
  }

  static EmergencyProtocol policeEmergency(String langCode) {
    switch (langCode) {
      case 'fr':
        return EmergencyProtocol(
          id: 'police', name: 'Urgence Sécurité',
          description: 'Alerte police',
          steps: ['SÉCURITÉ immédiate.', 'Appelez 17.', 'Position + menace.', 'Restez en ligne.'],
          emergencyNumber: '17',
        );
      case 'ar':
        return EmergencyProtocol(
          id: 'police', name: 'طوارئ أمنية',
          description: 'تنبيه شرطة',
          steps: ['أمان فوري.', 'اتصل بـ 17.', 'الموقع + التهديد.', 'ابقَ متصلاً.'],
          emergencyNumber: '17',
        );
      case 'en':
        return EmergencyProtocol(
          id: 'police', name: 'Security Emergency',
          description: 'Police alert',
          steps: ['SAFETY first.', 'Call 17.', 'Location + threat.', 'Stay on line.'],
          emergencyNumber: '17',
        );
      default:
        return policeEmergency('fr');
    }
  }

  static EmergencyProtocol burn(String langCode) {
    switch (langCode) {
      case 'fr':
        return EmergencyProtocol(
          id: 'burn', name: 'Brûlure',
          description: 'Premiers soins',
          steps: ['EAU FROIDE 20 min.', 'Retirez bijoux.', 'Film plastique.', 'Appelez 15.'],
          emergencyNumber: '15',
        );
      case 'ar':
        return EmergencyProtocol(
          id: 'burn', name: 'حروق',
          description: 'إسعاف أولي',
          steps: ['ماء بارد 20 دقيقة.', 'إزالة مجوهرات.', 'فيلم بلاستيك.', 'اتصل بـ 15.'],
          emergencyNumber: '15',
        );
      case 'en':
        return EmergencyProtocol(
          id: 'burn', name: 'Burn',
          description: 'First aid',
          steps: ['COLD WATER 20 min.', 'Remove jewelry.', 'Plastic wrap.', 'Call 15.'],
          emergencyNumber: '15',
        );
      default:
        return burn('fr');
    }
  }

  static EmergencyProtocol medicalEmergency(String langCode) {
    switch (langCode) {
      case 'fr':
        return EmergencyProtocol(
          id: 'medical', name: 'Urgence Médicale',
          description: 'Urgence générale',
          steps: ['Restez CALME.', 'Ne déplacez PAS.', 'Appelez 15.', 'Notez symptômes.'],
          emergencyNumber: '15',
        );
      case 'ar':
        return EmergencyProtocol(
          id: 'medical', name: 'طوارئ طبية',
          description: 'طوارئ عامة',
          steps: ['اهدأ.', 'لا تحرك.', 'اتصل بـ 15.', 'سجّل الأعراض.'],
          emergencyNumber: '15',
        );
      case 'en':
        return EmergencyProtocol(
          id: 'medical', name: 'Medical Emergency',
          description: 'General emergency',
          steps: ['Stay CALM.', 'Do NOT move.', 'Call 15.', 'Note symptoms.'],
          emergencyNumber: '15',
        );
      default:
        return medicalEmergency('fr');
    }
  }
}

enum EmergencyType { medical, police, fire }