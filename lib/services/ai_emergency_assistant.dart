import 'dart:async';
import 'package:stacked/stacked.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/app_config.dart';
import 'ai_tts_service.dart';

/// AI Emergency Assistant Service
/// Provides conversational AI guidance during emergencies
class AIEmergencyAssistant with ListenableServiceMixin {
  GenerativeModel? _chatModel;
  ChatSession? _chatSession;
  
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

  AIEmergencyAssistant(this._ttsService) {
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    try {
      _chatModel = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: AppConfig.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.2,
          maxOutputTokens: 1024,
        ),
      );
      
      _startNewSession();
    } catch (e) {
      print('AI Assistant initialization error: $e');
    }
  }

  void _startNewSession() {
    if (_chatModel != null) {
      _chatSession = _chatModel!.startChat(history: [
        Content.text('''
Tu es un assistant d'urgence médicale professionnel pour SOS Algérie. 
Tu dois:
1. Fournir des instructions claires et concises
2. Rester calme et rassurant
3. Poser des questions pour évaluer la situation
4. Guider étape par étape
5. Prioriser la sécurité de la victime

Réponds en français, de manière concise (1-2 phrases max par message).
'''),
      ]);
    }
  }

  /// Start a new emergency session
  Future<void> startEmergencySession({
    required String emergencyType,
    String? userMessage,
    String? location,
  }) async {
    _isEmergencyActive.value = true;
    _messages.value = [];
    _currentStepIndex.value = 0;
    notifyListeners();
    
    // Load appropriate protocol
    _activeProtocol = EmergencyProtocols.getProtocol(emergencyType);
    
    if (_activeProtocol != null) {
      // Use predefined protocol
      await _startProtocolGuidance(_activeProtocol!);
    } else {
      // Use AI for dynamic guidance
      await _startAIGuidance(emergencyType, userMessage, location);
    }
  }

  /// Start predefined protocol guidance
  Future<void> _startProtocolGuidance(EmergencyProtocol protocol) async {
    // Welcome message
    final welcomeMessage = ChatMessage(
      isUser: false,
      text: "Urgence détectée: ${protocol.name}. Je vais vous guider étape par étape.",
      timestamp: DateTime.now(),
    );
    _addMessage(welcomeMessage);
    
    await _ttsService.speak(welcomeMessage.text, urgent: true);
    await Future.delayed(const Duration(seconds: 2));
    
    // Start step-by-step guidance
    _processNextStep();
  }

  /// Process next step in the protocol
  Future<void> _processNextStep() async {
    if (_activeProtocol == null || _currentStepIndex.value >= _activeProtocol!.steps.length) {
      // Protocol complete
      final completeMessage = ChatMessage(
        isUser: false,
        text: "Protocole terminé. Les secours sont en route. Continuez à surveiller la victime.",
        timestamp: DateTime.now(),
        isImportant: true,
      );
      _addMessage(completeMessage);
      await _ttsService.speak(completeMessage.text, urgent: true);
      return;
    }
    
    final step = _activeProtocol!.steps[_currentStepIndex.value];
    _currentStep.value = step;
    
    final stepMessage = ChatMessage(
      isUser: false,
      text: "Étape ${_currentStepIndex.value + 1}: $step",
      timestamp: DateTime.now(),
      isStep: true,
      stepNumber: _currentStepIndex.value + 1,
    );
    _addMessage(stepMessage);
    
    await _ttsService.speak(stepMessage.text, urgent: true);
    
    // Auto-advance after delay (or wait for user confirmation)
    _stepTimer = Timer(const Duration(seconds: 15), () {
      if (_isEmergencyActive.value) {
        _currentStepIndex.value++;
        notifyListeners();
        _processNextStep();
      }
    });
  }

  /// Start AI-powered dynamic guidance
  Future<void> _startAIGuidance(
    String emergencyType,
    String? userMessage,
    String? location,
  ) async {
    _isProcessing.value = true;
    notifyListeners();
    
    final prompt = '''
L'utilisateur a signalé une urgence de type: $emergencyType
${userMessage != null ? 'Message: $userMessage' : ''}
${location != null ? 'Localisation: $location' : ''}

Fournis la première instruction immédiate (1 phrase max) et pose une question pour évaluer la gravité.
''';try {
      final response = await _chatSession?.sendMessage(Content.text(prompt));
      final aiResponse = response?.text ?? _getFallbackResponse(emergencyType);
      
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
  Future<void> processUserMessage(String message) async {
    print('🤖 [AI] User: "$message"');
    if (!_isEmergencyActive.value) return;
    
    // Add user message
    final userChatMessage = ChatMessage(
      isUser: true,
      text: message,
      timestamp: DateTime.now(),
    );
    _addMessage(userChatMessage);
    
    _isProcessing.value = true;
    notifyListeners();
    
    // Cancel auto-advance timer
    _stepTimer?.cancel();
    
    // Check for step advancement keywords
    if (_isAdvancementRequest(message)) {
      _currentStepIndex.value++;
      notifyListeners();
      await _processNextStep();
      _isProcessing.value = false;
      notifyListeners();
      return;
    }
    
    // Process with AI
    try {
      final response = await _chatSession?.sendMessage(Content.text(message));
      final aiResponse = response?.text ?? "Je comprends. Continuez à suivre les instructions.";
      
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

  /// Check if user wants to advance to next step
  bool _isAdvancementRequest(String message) {
    final lowerMessage = message.toLowerCase();
    final advancementKeywords = [
      'ok', 'd\'accord', 'fait', 'terminé', 'suivant', 'prochain',
      'étape suivante', 'c\'est bon', 'compris', 'je continue',
    ];
    
    return advancementKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  void _addMessage(ChatMessage message) {
    _messages.value = [..._messages.value, message];
    notifyListeners();
  }

  /// Advance to next step manually
  Future<void> nextStep() async {
    _stepTimer?.cancel();
    _currentStepIndex.value++;
    notifyListeners();
    await _processNextStep();
  }

  /// Repeat current step
  Future<void> repeatStep() async {
    if (_currentStep.value.isNotEmpty && !_ttsService.isSpeaking) {
      final repeatText = "je répète" + ': ${_currentStep.value}';
      await _ttsService.speak(repeatText, urgent: true);
    }
  }

  /// End emergency session
  Future<void> endEmergencySession() async {
    _stepTimer?.cancel();
    _isEmergencyActive.value = false;
    _activeProtocol = null;
    
    final endMessage = ChatMessage(
      isUser: false,
      text: "Session d'urgence terminée. Les secours sont arrivés. Prenez soin de vous.",
      timestamp: DateTime.now(),
      isImportant: true,
    );
    _addMessage(endMessage);
    
    await _ttsService.speak(endMessage.text);
    
    notifyListeners();
    _startNewSession();
  }

  String _getFallbackResponse(String emergencyType) {
    final responses = {
      'cardiac': 'Restez calme. Si la personne ne respire pas, commencez les compressions thoraciques.',
      'bleeding': 'Appliquez une pression directe sur la plaie avec un tissu propre.',
      'choking': 'Encouragez la personne à tousser. Si elle ne peut pas respirer, faites la manœuvre de Heimlich.',
      'fire': 'Évacuez immédiatement. Ne prenez pas l\'ascenseur. Appelez les pompiers.',
    };
    
    return responses[emergencyType.toLowerCase()] ?? 
           'Restez calme. Les secours sont en route. Suivez mes instructions.';
  }

  void dispose() {
    _stepTimer?.cancel();
  }
}

/// Chat Message Model
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
