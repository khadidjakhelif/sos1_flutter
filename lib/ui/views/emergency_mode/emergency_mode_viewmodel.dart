import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:sos1/models/language.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sos1/app/app.locator.dart';
import 'package:sos1/services/ai_emergency_assistant.dart';
import 'package:sos1/services/ai_tts_service.dart';
import 'package:sos1/services/language_service.dart';
import 'package:sos1/services/sos_history_service.dart';
import 'package:sos1/models/sos_incident.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:sos1/services/emergency_actions_service.dart';


class EmergencyModeViewModel extends BaseViewModel {
  final _aiAssistant = locator<AIEmergencyAssistant>();
  final _aiTts = locator<AITtsService>();
  final _historyService = locator<SOSHistoryService>();
  final _navigationService = locator<NavigationService>();
  final _languageService = locator<LanguageService>();
  final _emergencyActions = locator<EmergencyActionsService>();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool get isListening => _isListening;
  
  // Reactive state
  bool get isProcessing => _aiAssistant.isProcessing;
  List<ChatMessage> get messages => _aiAssistant.messages;
  String get currentStep => _aiAssistant.currentStep;
  int get currentStepIndex => _aiAssistant.currentStepIndex;
  bool get isEmergencyActive => _aiAssistant.isEmergencyActive;
  bool get isSpeaking => _aiTts.isSpeaking;
  
  // Emergency info
  String _emergencyType = '';
  String _emergencyDescription = '';
  String? _userLocation;
  DateTime _emergencyStartTime = DateTime.now();
  
  String get emergencyType => _emergencyType;
  String get emergencyDescription => _emergencyDescription;
  String? get userLocation => _userLocation;
  
  Timer? _elapsedTimer;
  final ReactiveValue<Duration> _elapsedTime = ReactiveValue<Duration>(Duration.zero);
  Duration get elapsedTime => _elapsedTime.value;

  final TextEditingController textController = TextEditingController();

  String get currentLanguage => _languageService.currentLanguage.displayName;
  String get languageCode => _languageService.currentLanguage.code;

  @override
  void dispose() {
    _speech.cancel();
    textController.dispose();
    _elapsedTimer?.cancel();
    super.dispose();
  }
  
  String get formattedElapsedTime {
    final minutes = _elapsedTime.value.inMinutes.toString().padLeft(2, '0');
    final seconds = (_elapsedTime.value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _chatInput = '';
  String get chatInput => _chatInput;
  set chatInput(String value) {
    _chatInput = value;
    notifyListeners();
  }

  Future<void> initialize({
    required String emergencyType,
    String? emergencyDescription,
    String? location,
  }) async {
    setBusy(true);

    await _initSpeech();

    _emergencyType = emergencyType;
    _emergencyDescription = emergencyDescription ?? '';
    _userLocation = location;
    _emergencyStartTime = DateTime.now();
    
    // Start elapsed time counter
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedTime.value = DateTime.now().difference(_emergencyStartTime);
      notifyListeners();
    });
    
    // Start AI emergency session
    await _aiAssistant.startEmergencySession(
      emergencyType: emergencyType,
      userMessage: emergencyDescription,
      location: location,
    );
    
    setBusy(false);
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onError: (error) {
        print('STT error: $error');
        _isListening = false;
        notifyListeners();
      },
      onStatus: (status) {
        // When the mic stops naturally (silence timeout), auto-send
        if (status == 'done' && _isListening) {
          _isListening = false;
          notifyListeners();
          _sendTranscript();
        }
      },
    );
  }

  Future<void> toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
      _sendTranscript();
    } else {
      _isListening = true;
      print('🎤 Toggle listening - Language: ${_languageService.currentLanguage.code}');
      notifyListeners();
      await _speech.listen(
        onResult: (result) {
          // Live transcript appears in the text field as user speaks
          textController.text = result.recognizedWords;
          textController.selection = TextSelection.fromPosition(
            TextPosition(offset: textController.text.length),
          );
          notifyListeners();
        },
        localeId: _getLocaleId(),   // get app language
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(seconds: 30),
      );
    }
  }

  void _sendTranscript() {
    final text = textController.text.trim();
    if (text.isNotEmpty) {
      sendMessage(text);
      textController.clear();
    }
  }

  String _getLocaleId() {
    final langMap = {
      'fr': 'fr-FR',
      'ar': 'ar-DZ',
      'en': 'en-US',
    };
    return langMap[_languageService.currentLanguage.code] ?? 'fr-FR';
  }

  Future<void> sendMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isNotEmpty) {
      print('📤 [1] sendMessage START: "$trimmed"');
      await _aiAssistant.processUserMessage(trimmed,_languageService.getLanguageCode());
      print('📤 [3] AI processing COMPLETE');
      notifyListeners();
      print('📤 [4] UI notified');
    }
  }

  String _getEmergencyNumber(String type) {
    final numbers = {
      'cardiac': '15',
      'medical': '15',
      'bleeding': '15',
      'choking': '15',
      'unconscious': '15',
      'fire': '14',
      'police': '17',
    };
    return numbers[type.toLowerCase()] ?? '15';
  }

  Future<void> nextStep() async {
    await _aiAssistant.nextStep();
  }

  Future<void> repeatStep() async {
    await _aiAssistant.repeatStep();
  }

  Future<void> callEmergencyServices() async {
    final langCode = _languageService.currentLanguage.code;

    // ✅ Language-aware confirmation
    final confirmation = {
      'fr': "Envoi des alertes SMS et appel des secours en cours.",
      'ar': "إرسال تنبيهات SMS والاتصال بخدمات الطوارئ جارٍ.",
      'en': "Sending SMS alerts and calling emergency services.",
    }[langCode] ?? "Sending SMS alerts and calling emergency services.";

    await _aiTts.speak(confirmation, urgent: true);
  
    // Trigger full SOS: SMS to all contacts + auto-call first contact
    await _emergencyActions.triggerFullSOS(
      emergencyType: _emergencyType,
      customMessage: _emergencyDescription,
    );
  }

  Future<void> shareLocation() async {
    final langCode = _languageService.currentLanguage.code;
    final message = {
      'fr': "Partage de votre position GPS avec les secours.",
      'ar': "مشاركة موقع GPS الخاص بك مع خدمات الإنقاذ.",
      'en': "Sharing your GPS location with emergency services.",
    }[langCode] ?? "Sharing your location.";

    await _aiTts.speak(message, urgent: true);
    await _aiTts.speak(
      "Partage de votre position GPS en cours.",
      urgent: true,
    );

    await _emergencyActions.sendSOSToAllContacts(
      emergencyType: _emergencyType,
      customMessage: 'Partage de position manuel',
    );
  }

  Future<void> endEmergency() async {
    _elapsedTimer?.cancel();
    
    // Save to history
    await _saveToHistory();
    
    // End AI session
    await _aiAssistant.endEmergencySession();
    
    // Navigate back
    _navigationService.back();
  }

  Future<void> _saveToHistory() async {
    final incident = SOSIncident(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _emergencyType,
      type: _getIncidentType(_emergencyType),
      timestamp: _emergencyStartTime,
      location: _userLocation ?? 'Position inconnue',
      status: 'completed',
      details: _emergencyDescription,
    );
    
    await _historyService.addIncident(incident);
  }

  IncidentType _getIncidentType(String emergencyType) {
    final types = {
      'cardiac': IncidentType.medical,
      'medical': IncidentType.medical,
      'bleeding': IncidentType.medical,
      'choking': IncidentType.medical,
      'unconscious': IncidentType.medical,
      'fire': IncidentType.fire,
      'police': IncidentType.security,
    };
    return types[emergencyType.toLowerCase()] ?? IncidentType.other;
  }

}
