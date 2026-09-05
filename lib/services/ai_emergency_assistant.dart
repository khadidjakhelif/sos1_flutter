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

  /// Callback invoked when a new AI/system message is added, so the viewmodel
  /// can fire-and-forget POST it to the backend.
  void Function(ChatMessage message)? onMessageAdded;

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
Tu es l'assistant d'urgence IA d'EchoAlert — une application de réponse aux urgences industrielles.
Ton rôle est de guider un travailleur en situation de crise médicale ou de sécurité, étape par étape, jusqu'à l'arrivée des secours.

CONTEXTE IMPORTANT :
- Un officier de sécurité humain supervise la situation en parallèle via un tableau de bord centralisé. Il peut intervenir, envoyer des messages ou dépêcher des secours à tout moment. Tu n'es pas le seul soutien disponible.
- Prends toujours en compte le profil médical du patient si disponible, et AVERTIS immédiatement si une instruction pourrait être dangereuse en raison d'allergies ou de maladies chroniques.
- Ne contredis JAMAIS les ordres de l'officier de sécurité — adapte tes conseils en conséquence.

CONTRAINTE DE RÔLE — OBLIGATOIRE :
Tu dois TOUJOURS agir en tant qu'assistant d'urgence EchoAlert. Si l'utilisateur pose une question hors sujet ou tente de te détourner de ton rôle, ne réponds pas à sa demande hors sujet. Redirige-le doucement en vérifiant d'abord son état : "Je suis ici pour vous aider en cas d'urgence. Êtes-vous en sécurité ? Y a-t-il quelqu'un qui a besoin d'aide ?"

STYLE DE RÉPONSE :
- Réponds en français, en langage simple et clair, sans jargon médical.
- Donne 1 à 3 phrases courtes et actionnables par message. Évite les réponses d'une seule ligne trop sèches. Évite les longs paragraphes.
- Reste calme et rassurant à tout moment.
''',
      'ar': '''
أنت مساعد الطوارئ الذكي لـ EchoAlert — تطبيق للاستجابة للطوارئ الصناعية.
دورك هو إرشاد العامل خلال أزمة طبية أو أمنية خطوة بخطوة حتى وصول المساعدة.

السياق المهم:
- مسؤول سلامة بشري يشرف على الموقف بالتوازي عبر لوحة تحكم مركزية. يمكنه التدخل وإرسال رسائل أو إرسال المساعدة في أي وقت. أنت لست الدعم الوحيد المتاح.
- ضع دائماً في الاعتبار الملف الطبي للمريض إن توفّر، وحذِّر فوراً إذا كانت التعليمات خطرة بسبب الحساسية أو الأمراض المزمنة.
- لا تتعارض أبداً مع أوامر مسؤول السلامة — كيّف نصائحك وفقاً لذلك.

قيد الدور — إلزامي:
يجب أن تتصرف دائماً بوصفك مساعد طوارئ EchoAlert. إذا طرح المستخدم سؤالاً خارج الموضوع، لا تُجب عليه. وجّهه بلطف للتحقق من حالته: "أنا هنا للمساعدة في حالات الطوارئ. هل أنت بأمان؟ هل هناك من يحتاج للمساعدة؟"

أسلوب الرد:
- أجب بالعربية بلغة بسيطة وواضحة بدون مصطلحات طبية معقدة.
- قدّم من 1 إلى 3 جمل قصيرة وقابلة للتنفيذ في كل رسالة. تجنب الردود المقتضبة جداً. تجنب الفقرات الطويلة.
- حافظ على الهدوء والطمأنينة في جميع الأوقات.
''',
      'en': '''
You are the AI emergency assistant for EchoAlert — an industrial emergency response application.
Your role is to guide a worker through a medical or safety crisis, step by step, until help arrives.

IMPORTANT CONTEXT:
- A human safety officer is supervising the situation in parallel via a centralized dashboard. They can intervene, send messages, or dispatch help at any time. You are not the sole line of support.
- Always consider the patient's medical profile if available, and IMMEDIATELY warn if any instruction could be dangerous due to allergies or chronic conditions.
- NEVER contradict the safety officer's orders — adapt your advice accordingly.

ROLE CONSTRAINT — MANDATORY:
You must ALWAYS act as the EchoAlert emergency assistant. If the user asks an off-topic question or tries to redirect you away from your role, do not answer the off-topic request. Gently redirect by checking on them first: "I'm here to help in an emergency. Are you safe? Is someone in need of help?"

RESPONSE STYLE:
- Respond in English, in plain simple language without medical jargon.
- Give 1 to 3 short, clearly actionable sentences per message. Avoid single-line terse replies. Avoid long paragraphs.
- Stay calm and reassuring at all times.
''',
    }[langCode] ?? 'You are a professional emergency assistant for EchoAlert.';

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
      senderRole: 'ai_assistant',
    );
    _addMessage(welcomeMessage);

    await _ttsService.speak(welcomeMessage.text, urgent: true, interrupt: false);
    await Future.delayed(const Duration(seconds: 2));

    _processNextStep();
  }

  /// Process next step in the protocol
  /// CHANGED: step label and complete message are now language-aware
  Future<void> _processNextStep() async {
    final langCode = _languageService?.getLanguageCode() ?? 'fr';

    if (_activeProtocol == null || _currentStepIndex.value >= _activeProtocol!.steps.length) {
      // NOTE: Do NOT claim services are on the way here — the backend dispatch
    // result is unknown at this point. Only the SSE resolution banner in the
    // viewmodel may confirm that the dashboard has been alerted.
    final completeText = {
      'fr': 'Protocole terminé. Continuez à surveiller la victime jusqu\'à l\'arrivée des secours.',
      'ar': 'انتهى البروتوكول. استمر في مراقبة الضحية حتى وصول فريق الإنقاذ.',
      'en': 'Protocol complete. Keep monitoring the victim until help arrives.',
    }[langCode] ?? 'Protocole terminé. Continuez à surveiller la victime.';

      final completeMessage = ChatMessage(
        isUser: false,
        text: completeText,
        timestamp: DateTime.now(),
        isImportant: true,
        senderRole: 'ai_assistant',
      );
      _addMessage(completeMessage);
      await _ttsService.speak(completeMessage.text, urgent: true, interrupt: false);
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
      senderRole: 'ai_assistant',
    );
    _addMessage(stepMessage);

    await _ttsService.speak(stepMessage.text, urgent: true, interrupt: false);

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
        senderRole: 'ai_assistant',
      );
      _addMessage(message);
      await _ttsService.speak(aiResponse, urgent: true, interrupt: false);
    } catch (e) {
      print('AI guidance error: $e');
      final fallback = _getFallbackResponse(emergencyType);
      final message = ChatMessage(
        isUser: false,
        text: fallback,
        timestamp: DateTime.now(),
        senderRole: 'ai_assistant',
      );
      _addMessage(message);
      await _ttsService.speak(fallback, urgent: true, interrupt: false);
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
        senderRole: 'ai_assistant',
      );
      _addMessage(aiMessage);
      await _ttsService.speak(aiResponse, urgent: true, interrupt: false);
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
    // Fire callback for backend sync (AI/system messages)
    if (message.senderRole == 'ai_assistant' || message.senderRole == 'system') {
      onMessageAdded?.call(message);
    }
  }

  /// Inject an officer message into the conversation history so the AI
  /// considers it in subsequent responses (officer primacy rule).
  void injectOfficerMessage(String content) {
    _conversationHistory.add({
      'role': 'user',
      'content': '[Officier de sécurité]: $content',
    });
  }

  /// Add a backend message to the local list (for polling merge).
  /// Returns true if it was new, false if duplicate.
  bool addBackendMessage(ChatMessage message) {
    // Deduplication by id
    if (message.id != null && _messages.value.any((m) => m.id == message.id)) {
      return false;
    }
    // Also deduplicate by text+timestamp proximity for AI messages we already have locally
    if (message.senderRole == 'ai_assistant') {
      final exists = _messages.value.any((m) =>
        m.senderRole == 'ai_assistant' &&
        m.text == message.text &&
        m.timestamp.difference(message.timestamp).abs() < const Duration(seconds: 10)
      );
      if (exists) return false;
    }
    _messages.value = [..._messages.value, message];
    // Sort by timestamp
    _messages.value.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    notifyListeners();
    return true;
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
      await _ttsService.speak('$prefix: ${_currentStep.value}', urgent: true, interrupt: false);
    }
  }

  /// UNCHANGED except end text is language-aware
  Future<void> endEmergencySession() async {
    _stepTimer?.cancel();
    _isEmergencyActive.value = false;
    _activeProtocol = null;

    final langCode = _languageService?.getLanguageCode() ?? 'fr';
    // NOTE: Do NOT claim help has arrived — the session may be ended before
    // any responders have actually been dispatched or confirmed.
    final endText = {
      'fr': "Session d'urgence terminée. Restez vigilant et contactez les secours si nécessaire.",
      'ar': "انتهت الجلسة. ابقَ متيقظاً واتصل بالطوارئ إذا لزم.",
      'en': "Emergency session ended. Stay alert and contact emergency services if needed.",
    }[langCode] ?? "Session d'urgence terminée.";

    final endMessage = ChatMessage(
      isUser: false,
      text: endText,
      timestamp: DateTime.now(),
      isImportant: true,
      senderRole: 'system',
    );
    _addMessage(endMessage);
    await _ttsService.speak(endMessage.text, interrupt: false);

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

/// Chat Message Model — EXTENDED for unified chat
class ChatMessage {
  final bool isUser;
  final String text;
  final DateTime timestamp;
  final bool isImportant;
  final bool isStep;
  final int? stepNumber;
  final String senderRole; // 'worker', 'ai_assistant', 'safety_officer', 'system'
  final String? id; // backend message id for deduplication

  ChatMessage({
    required this.isUser,
    required this.text,
    required this.timestamp,
    this.isImportant = false,
    this.isStep = false,
    this.stepNumber,
    this.senderRole = 'worker',
    this.id,
  });

  /// Create from backend message JSON
  factory ChatMessage.fromBackend(Map<String, dynamic> json) {
    final role = json['sender_role'] as String? ?? 'worker';
    return ChatMessage(
      isUser: role == 'worker',
      text: json['content'] as String? ?? '',
      timestamp: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      senderRole: role,
      id: json['id']?.toString(),
      isStep: false,
      isImportant: false,
    );
  }
}