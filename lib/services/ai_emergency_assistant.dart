import 'dart:async';
import 'package:stacked/stacked.dart';
import '../models/medical_profile.dart';
import '../utils/app_config.dart';
import '../services/ai_provider_service.dart';
import 'ai_tts_service.dart';
import 'language_service.dart';
import 'medical_profile_service.dart';

/// AI Emergency Assistant Service
/// Provides conversational AI guidance during emergencies
class AIEmergencyAssistant with ListenableServiceMixin {
  // CHANGED: replaced GenerativeModel + ChatSession with AIProviderService
  final AIProviderService _aiProvider = AIProviderService();
  final List<Map<String, String>> _conversationHistory = [];

  LanguageService? _languageService;

  final ReactiveValue<bool> _isProcessing = ReactiveValue<bool>(false);
  final ReactiveValue<List<ChatMessage>> _messages = ReactiveValue<List<ChatMessage>>([]);
  final ReactiveValue<String> _currentStep = ReactiveValue<String>('');
  final ReactiveValue<int> _currentStepIndex = ReactiveValue<int>(0);
  final ReactiveValue<bool> _isEmergencyActive = ReactiveValue<bool>(false);

  bool get isProcessing => _isProcessing.value;
  List<ChatMessage> get messages => _messages.value;
  String get currentStep => _currentStep.value;
  int get currentStepIndex => _currentStepIndex.value;
  bool get isEmergencyActive => _isEmergencyActive.value;

  EmergencyProtocol? _activeProtocol;
  Timer? _stepTimer;
  final AITtsService _ttsService;
  final MedicalProfileService? _medicalProfileService;

  AIEmergencyAssistant(this._ttsService, [this._languageService, this._medicalProfileService]) {
    _initializeAI();
  }

  // CHANGED: initialize AIProviderService instead of GenerativeModel
  Future<void> _initializeAI() async {
    try {
      await _aiProvider.initialize(systemPrompt: _buildSystemPrompt());
      print('✅ AI initialized: ${_aiProvider.providerName}');
    } catch (e) {
      print('AI Assistant initialization error: $e');
    }
  }

  // CHANGED: reset history + provider session instead of rebuilding ChatSession
  void _startNewSession() {
    _conversationHistory.clear();
    _aiProvider.resetSession(systemPrompt: _buildSystemPrompt());
  }

  String _buildProfileContext() {
    final profile = _medicalProfileService?.profile;
    if (profile == null) return '';

    final parts = <String>[];

    if (profile.fullName.isNotEmpty) {
      parts.add('Patient name: ${profile.fullName}');
    }

    parts.add('Blood type: ${profile.bloodType.fullDisplayName}');

    if (profile.isUniversalDonor) {
      parts.add('Universal donor: yes (O-)');
    }

    if (profile.chronicDiseases.isNotEmpty) {
      parts.add('Chronic diseases: ${profile.chronicDiseases.join(', ')}');
    }

    if (profile.allergies.isNotEmpty) {
      parts.add('⚠️ ALLERGIES (critical): ${profile.allergies.join(', ')}');
    }

    if (profile.emergencyNotes.isNotEmpty) {
      parts.add('Emergency notes: ${profile.emergencyNotes}');
    }

    if (profile.iceContact != null) {
      parts.add('ICE contact: ${profile.iceContact!.name} (${profile.iceContact!.relation}) — ${profile.iceContact!.phoneNumber}');
    }

    if (parts.isEmpty) return '';

    return '''

--- PATIENT MEDICAL PROFILE ---
${parts.join('\n')}
--- END OF PROFILE ---
''';
  }

  // picks language from LanguageService --STILL NEEDS UPDATE--
  String _buildSystemPrompt() {
    final langCode = _languageService?.getLanguageCode() ?? 'fr';
    final basePrompt = {
      'fr': '''
Tu es un assistant d'urgence médicale professionnel pour SOS Algérie.
Tu dois:
1. Fournir des instructions claires et concises
2. Rester calme et rassurant
3. Poser des questions pour évaluer la situation
4. Guider étape par étape
5. Prioriser la sécurité de la victime
6. TOUJOURS tenir compte du profil médical du patient si disponible
7. AVERTIR immédiatement si une instruction pourrait être dangereuse vu les allergies ou maladies

Réponds en français, de manière concise (1-2 phrases max par message).
''',
      'ar': '''
أنت مساعد طوارئ طبية محترف لـ SOS الجزائر.
يجب عليك:
1. تقديم تعليمات واضحة وموجزة
2. البقاء هادئاً ومطمئناً
3. طرح أسئلة لتقييم الوضع
4. التوجيه خطوة بخطوة
5. إعطاء الأولوية لسلامة الضحية
6. مراعاة الملف الطبي للمريض دائماً إن توفر
7. التحذير فوراً إذا كانت التعليمات خطيرة بسبب الحساسية أو الأمراض

أجب بالعربية، جملتين كحد أقصى.
''',
      'en': '''
You are a professional medical emergency assistant for SOS Algeria.
You must:
1. Provide clear and concise instructions
2. Stay calm and reassuring
3. Ask questions to assess the situation
4. Guide step by step
5. Prioritize the victim's safety
6. ALWAYS consider the patient's medical profile if available
7. IMMEDIATELY warn if an instruction could be dangerous given allergies or conditions

Respond in English, 1-2 sentences max per message.
''',
    }[langCode] ?? 'You are a professional emergency assistant.';

    // Append profile
    return basePrompt + _buildProfileContext();
  }

  /// Start a new emergency session
  Future<void> startEmergencySession({
    required String emergencyType,
    String? userMessage,
    String? location,
    String language = 'Francais',
  }) async {
    _isEmergencyActive.value = true;
    _messages.value = [];
    _currentStepIndex.value = 0;
    _startNewSession(); // CHANGED: resets history for each new emergency
    notifyListeners();

    _activeProtocol = EmergencyProtocols.getProtocol(emergencyType);

    if (_activeProtocol != null) {
      await _startProtocolGuidance(_activeProtocol!);
    } else {
      await _startAIGuidance(emergencyType, userMessage, location);
    }
  }

  /// Start predefined protocol guidance
  /// CHANGED: welcome text is now language-aware
  Future<void> _startProtocolGuidance(EmergencyProtocol protocol) async {
    final langCode = _languageService?.getLanguageCode() ?? 'fr';
    final welcomeText = {
      'fr': 'Urgence détectée: ${protocol.name}. Je vais vous guider étape par étape.',
      'ar': 'تم اكتشاف حالة طوارئ: ${protocol.name}. سأرشدك خطوة بخطوة.',
      'en': 'Emergency detected: ${protocol.name}. I will guide you step by step.',
    }[langCode] ?? 'Urgence détectée: ${protocol.name}.';

    final welcomeMessage = ChatMessage(
      isUser: false,
      text: welcomeText,
      timestamp: DateTime.now(),
    );
    _addMessage(welcomeMessage);

    await _ttsService.speak(welcomeMessage.text, urgent: true);
    await Future.delayed(const Duration(seconds: 2));

    _processNextStep();
  }

  /// Process next step in the protocol
  /// CHANGED: step label and complete message are now language-aware
  Future<void> _processNextStep() async {
    final langCode = _languageService?.getLanguageCode() ?? 'fr';

    if (_activeProtocol == null || _currentStepIndex.value >= _activeProtocol!.steps.length) {
      final completeText = {
        'fr': 'Protocole terminé. Les secours sont en route. Continuez à surveiller la victime.',
        'ar': 'انتهى البروتوكول. فرق الإنقاذ في الطريق. استمر في مراقبة الضحية.',
        'en': 'Protocol complete. Emergency services are on the way. Keep monitoring the victim.',
      }[langCode] ?? 'Protocole terminé.';

      final completeMessage = ChatMessage(
        isUser: false,
        text: completeText,
        timestamp: DateTime.now(),
        isImportant: true,
      );
      _addMessage(completeMessage);
      await _ttsService.speak(completeMessage.text, urgent: true);
      return;
    }

    final step = _activeProtocol!.steps[_currentStepIndex.value];
    _currentStep.value = step;

    final stepLabel = {
      'fr': 'Étape ${_currentStepIndex.value + 1}: $step',
      'ar': 'الخطوة ${_currentStepIndex.value + 1}: $step',
      'en': 'Step ${_currentStepIndex.value + 1}: $step',
    }[langCode] ?? 'Étape ${_currentStepIndex.value + 1}: $step';

    final stepMessage = ChatMessage(
      isUser: false,
      text: stepLabel,
      timestamp: DateTime.now(),
      isStep: true,
      stepNumber: _currentStepIndex.value + 1,
    );
    _addMessage(stepMessage);

    await _ttsService.speak(stepMessage.text, urgent: true);

    _stepTimer = Timer(const Duration(seconds: 15), () {
      if (_isEmergencyActive.value) {
        _currentStepIndex.value++;
        notifyListeners();
        _processNextStep();
      }
    });
  }

  /// Start AI-powered dynamic guidance
  /// CHANGED: _chatSession?.sendMessage → _aiProvider.sendMessage
  Future<void> _startAIGuidance(
      String emergencyType,
      String? userMessage,
      String? location,
      ) async {
    _isProcessing.value = true;
    notifyListeners();

    final langCode = _languageService?.getLanguageCode() ?? 'fr';
    final langName = {'fr': 'French', 'ar': 'Arabic', 'en': 'English'}[langCode] ?? 'French';

    final prompt = '''
Emergency type: $emergencyType
${userMessage != null ? 'Message: $userMessage' : ''}
${location != null ? 'Location: $location' : ''}

Provide the first immediate instruction (1 sentence max) and ask one question to assess severity.
Respond in $langName.
''';

    try {
      // CHANGED: was _chatSession?.sendMessage(Content.text(prompt))?.text
      final aiResponse = await _aiProvider.sendMessage(
        prompt,
        history: _conversationHistory,
        systemPrompt: _buildSystemPrompt(),
      ) ?? _getFallbackResponse(emergencyType);

      _conversationHistory.add({'role': 'user', 'content': prompt});
      _conversationHistory.add({'role': 'assistant', 'content': aiResponse});

      final message = ChatMessage(
        isUser: false,
        text: aiResponse,
        timestamp: DateTime.now(),
      );
      _addMessage(message);
      await _ttsService.speak(aiResponse, urgent: true);
    } catch (e) {
      print('AI guidance error: $e');
      final fallback = _getFallbackResponse(emergencyType);
      final message = ChatMessage(
        isUser: false,
        text: fallback,
        timestamp: DateTime.now(),
      );
      _addMessage(message);
      await _ttsService.speak(fallback, urgent: true);
    }

    _isProcessing.value = false;
    notifyListeners();
  }

  /// Process user message during emergency
  /// CHANGED: _chatSession?.sendMessage → _aiProvider.sendMessage
  Future<void> processUserMessage(String message, [String? languageCode]) async {
    print('🤖 [AI] User: "$message"');
    if (!_isEmergencyActive.value) return;

    final userChatMessage = ChatMessage(
      isUser: true,
      text: message,
      timestamp: DateTime.now(),
    );
    _addMessage(userChatMessage);

    _isProcessing.value = true;
    notifyListeners();

    _stepTimer?.cancel();

    if (_isAdvancementRequest(message)) {
      _currentStepIndex.value++;
      notifyListeners();
      await _processNextStep();
      _isProcessing.value = false;
      notifyListeners();
      return;
    }

    try {
      // CHANGED: was _chatSession?.sendMessage(Content.text(message))?.text
      _conversationHistory.add({'role': 'user', 'content': message});

      final aiResponse = await _aiProvider.sendMessage(
        message,
        history: _conversationHistory,
        systemPrompt: _buildSystemPrompt(),
      ) ?? _getFallbackResponse('medical');

      _conversationHistory.add({'role': 'assistant', 'content': aiResponse});

      final aiMessage = ChatMessage(
        isUser: false,
        text: aiResponse,
        timestamp: DateTime.now(),
      );
      _addMessage(aiMessage);
      await _ttsService.speak(aiResponse, urgent: true);
    } catch (e) {
      print('AI response error: $e');
    }

    _isProcessing.value = false;
    notifyListeners();
  }

  /// UNCHANGED except added English/Arabic advancement keywords
  bool _isAdvancementRequest(String message) {
    final lowerMessage = message.toLowerCase();
    final advancementKeywords = [
      // French (original)
      'ok', 'd\'accord', 'fait', 'terminé', 'suivant', 'prochain',
      'étape suivante', 'c\'est bon', 'compris', 'je continue',
      // English
      'done', 'next', 'continue', 'got it', 'okay', 'understood', 'proceed',
      // Arabic
      'تم', 'حسناً', 'موافق', 'التالي', 'فهمت', 'استمر',
    ];
    return advancementKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  void _addMessage(ChatMessage message) {
    _messages.value = [..._messages.value, message];
    notifyListeners();
  }

  /// UNCHANGED
  Future<void> nextStep() async {
    _stepTimer?.cancel();
    _currentStepIndex.value++;
    notifyListeners();
    await _processNextStep();
  }

  /// UNCHANGED except repeat prefix is language-aware
  Future<void> repeatStep() async {
    if (_currentStep.value.isNotEmpty && !_ttsService.isSpeaking) {
      final langCode = _languageService?.getLanguageCode() ?? 'fr';
      final prefix = {'fr': 'Je répète', 'ar': 'أعيد', 'en': 'Repeating'}[langCode] ?? 'Je répète';
      await _ttsService.speak('$prefix: ${_currentStep.value}', urgent: true);
    }
  }

  /// UNCHANGED except end text is language-aware
  Future<void> endEmergencySession() async {
    _stepTimer?.cancel();
    _isEmergencyActive.value = false;
    _activeProtocol = null;

    final langCode = _languageService?.getLanguageCode() ?? 'fr';
    final endText = {
      'fr': "Session d'urgence terminée. Les secours sont arrivés. Prenez soin de vous.",
      'ar': "انتهت الجلسة. وصلت فرق الإنقاذ. اعتنِ بنفسك.",
      'en': "Emergency session ended. Help has arrived. Take care of yourself.",
    }[langCode] ?? "Session d'urgence terminée.";

    final endMessage = ChatMessage(
      isUser: false,
      text: endText,
      timestamp: DateTime.now(),
      isImportant: true,
    );
    _addMessage(endMessage);
    await _ttsService.speak(endMessage.text);

    notifyListeners();
    _startNewSession();
  }

  /// UNCHANGED except now multilingual
  String _getFallbackResponse(String emergencyType) {
    final langCode = _languageService?.getLanguageCode() ?? 'fr';
    final responses = {
      'fr': {
        'cardiac': 'Restez calme. Si la personne ne respire pas, commencez les compressions thoraciques.',
        'bleeding': 'Appliquez une pression directe sur la plaie avec un tissu propre.',
        'choking': 'Encouragez la personne à tousser. Si elle ne peut pas respirer, faites la manœuvre de Heimlich.',
        'fire': 'Évacuez immédiatement. Ne prenez pas l\'ascenseur. Appelez les pompiers.',
      },
      'ar': {
        'cardiac': 'اهدأ. إذا لم يتنفس، ابدأ ضغطات الصدر.',
        'bleeding': 'اضغط مباشرة على الجرح بقماش نظيف.',
        'choking': 'شجع على السعال. إذا لم يتنفس، قم بمناورة هيمليك.',
        'fire': 'اخرج فوراً. لا تستخدم المصعد.',
      },
      'en': {
        'cardiac': 'Stay calm. If the person is not breathing, start chest compressions.',
        'bleeding': 'Apply direct pressure to the wound with a clean cloth.',
        'choking': 'Encourage the person to cough. If they cannot breathe, perform the Heimlich maneuver.',
        'fire': 'Evacuate immediately. Do not use the elevator. Call the fire department.',
      },
    };
    return responses[langCode]?[emergencyType.toLowerCase()]
        ?? responses['fr']![emergencyType.toLowerCase()]
        ?? 'Restez calme. Les secours sont en route. Suivez mes instructions.';
  }

  void dispose() {
    _stepTimer?.cancel();
  }
}

/// Chat Message Model — UNCHANGED
class ChatMessage {
  final bool isUser;
  final String text;
  final DateTime timestamp;
  final bool isImportant;
  final bool isStep;
  final int? stepNumber;

  ChatMessage({
    required this.isUser,
    required this.text,
    required this.timestamp,
    this.isImportant = false,
    this.isStep = false,
    this.stepNumber,
  });
}