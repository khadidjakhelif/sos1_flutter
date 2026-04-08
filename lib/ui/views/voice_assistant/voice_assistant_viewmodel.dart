import 'dart:async';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sos1/app/app.locator.dart';
import 'package:sos1/app/app.router.dart';
import 'package:sos1/services/ai_speech_service.dart';
import 'package:sos1/services/ai_tts_service.dart';
import 'package:sos1/utils/app_config.dart';
import 'package:sos1/services/language_service.dart';
import 'package:sos1/models/language.dart';

class VoiceAssistantViewModel extends BaseViewModel {
  final _aiSpeechService = locator<AISpeechService>();
  final _aiTtsService = locator<AITtsService>();
  final _languageService = locator<LanguageService>();
  final _navigationService = locator<NavigationService>();
  
  // Reactive state
  bool get isListening => _aiSpeechService.isListening;
  bool get isProcessing => _aiSpeechService.isProcessing || _aiTtsService.isProcessing;
  bool get isSpeaking => _aiTtsService.isSpeaking;
  String get recognizedWords => _aiSpeechService.recognizedWords;
  String get lastWords => _aiSpeechService.lastWords;
  EmergencyIntent? get detectedIntent => _aiSpeechService.detectedIntent;
  double get confidenceScore => _aiSpeechService.confidenceScore;
  String get currentLanguage => _languageService.currentLanguage.displayName;
  String get languageCode => _languageService.currentLanguage.code;
  
  // UI State
  bool _showEmergencyResponse = false;
  String _detectedEmergencyType = '';
  String _userCommand = '';
  bool _isAIEnabled = AppConfig.enableAIAssistant;
  
  bool get showEmergencyResponse => _showEmergencyResponse;
  String get detectedEmergencyType => _detectedEmergencyType;
  String get userCommand => _userCommand;
  bool get isAIEnabled => _isAIEnabled;
  
  StreamSubscription? _intentSubscription;
  
  Future<void> initialize() async {
    setBusy(true);
    
    // Initialize AI services
    await _aiSpeechService.initialize();
    await _aiTtsService.initialize();
    
    // Listen to AI intent detection
    _intentSubscription = _aiSpeechService.intentStream.listen(_onEmergencyDetected);
    
    // Speak AI greeting after a short delay
    Future.delayed(const Duration(milliseconds: 300), () async {
      final greeting = await _aiTtsService.generateEmergencyResponse(
        emergencyType: 'greeting',
        userMessage: 'initial_greeting',
      );
      await _aiTtsService.speak(greeting);
    });
    
    setBusy(false);
    notifyListeners();
  }
  
  void _onEmergencyDetected(EmergencyIntent intent) async {
    print('🔥 EMERGENCY DETECTED: ${intent.type} (${intent.confidence})');
    if (intent.isHighConfidence) {
      print('🚨 HIGH CONFIDENCE - Showing UI');
      _detectedEmergencyType = intent.type;
      _userCommand = intent.rawText;
      _showEmergencyResponse = true;
      notifyListeners();
      
      // Generate AI response
      final aiResponse = await _aiTtsService.generateEmergencyResponse(
        emergencyType: intent.type,
        userMessage: intent.rawText,
      );
      
      await _aiTtsService.speak(aiResponse, urgent: true);
      
      // Auto-navigate to emergency mode for high-confidence detections
      if (intent.needsImmediateResponse == true) {
        Future.delayed(const Duration(seconds: 3), () {
          navigateToEmergencyMode(intent);
        });
      }
    } else {
      print('ℹ️ Low confidence (${intent.confidence}) - No UI');
    }
    
    notifyListeners();
  }

  Future<void> toggleListening() async {
    try {
      print('🎤 Toggle listening - Language: ${_languageService.currentLanguage.code}');
      if (_aiSpeechService.isListening) {
        await _aiSpeechService.stopListening();
        _aiSpeechService.playStopBeep();
      } else {
        _showEmergencyResponse = false;
        _detectedEmergencyType = '';
        _userCommand = '';
        _aiSpeechService.clearRecognizedWords();
        notifyListeners();
        _aiSpeechService.playStartBeep();
        await _aiSpeechService.startListening();
      }
    } catch (e) {
      print('Microphone error: $e');
      // Show error to user
    } finally {
      notifyListeners();
    }
  }
  
  /// Navigate to Emergency Mode with detected emergency
  void navigateToEmergencyMode(EmergencyIntent? intent) {
    final emergencyType = intent?.type ?? _detectedEmergencyType;
    if (emergencyType.isEmpty) return;
    
    _navigationService.navigateToEmergencyModeView(
      emergencyType: emergencyType,
      emergencyDescription: intent?.rawText ?? _userCommand,
    );
  }
  
  /// Start emergency mode directly
  void startEmergencyMode(String emergencyType) {
    _navigationService.navigateToEmergencyModeView(
      emergencyType: emergencyType,
    );
  }

  // Fake emergency for testing
  Future<void> testFireEmergency() async {
    print('🧪 Manual fire test');
    final fakeIntent = EmergencyIntent(
      type: 'fire',
      confidence: 0.9,
      rawText: "Help there's a fire in",
      severity: 8,
      needsImmediateResponse: true,
    );
    _onEmergencyDetected(fakeIntent);
  }
  
  // Quick command handlers - now navigate directly to emergency mode
  Future<void> onSamuPressed() async {
    _detectedEmergencyType = 'medical';
    _userCommand = 'J\'ai besoin d\'une ambulance';
    _showEmergencyResponse = true;
    notifyListeners();
    
    final response = await _aiTtsService.generateEmergencyResponse(
      emergencyType: 'medical',
      userMessage: _userCommand,
    );
    await _aiTtsService.speak(response, urgent: true);
    
    Future.delayed(const Duration(seconds: 2), () {
      startEmergencyMode('medical');
    });
  }
  
  Future<void> onPolicePressed() async {
    _detectedEmergencyType = 'police';
    _userCommand = 'J\'ai besoin de la police';
    _showEmergencyResponse = true;
    notifyListeners();
    
    final response = await _aiTtsService.generateEmergencyResponse(
      emergencyType: 'police',
      userMessage: _userCommand,
    );
    await _aiTtsService.speak(response, urgent: true);
    
    Future.delayed(const Duration(seconds: 2), () {
      startEmergencyMode('police');
    });
  }
  
  Future<void> onPompiersPressed() async {
    _detectedEmergencyType = 'fire';
    _userCommand = 'J\'ai besoin des pompiers';
    _showEmergencyResponse = true;
    notifyListeners();
    
    final response = await _aiTtsService.generateEmergencyResponse(
      emergencyType: 'fire',
      userMessage: _userCommand,
    );
    await _aiTtsService.speak(response, urgent: true);
    
    Future.delayed(const Duration(seconds: 2), () {
      startEmergencyMode('fire');
    });
  }
  
  void resetEmergencyState() {
    _showEmergencyResponse = false;
    _detectedEmergencyType = '';
    _userCommand = '';
    _aiSpeechService.clearRecognizedWords();
    notifyListeners();
  }
  
  Future<void> goBack() async {
    await _navigationService.back();
  }
  
  void navigateToSettings() {
    _navigationService.navigateTo(Routes.settingsView);
  }
  
  @override
  void dispose() {
    _intentSubscription?.cancel();
    super.dispose();
  }
}

// Re-export for convenience
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
        return '15';
      case EmergencyType.police:
        return '17';
      case EmergencyType.fire:
        return '18';
    }
  }
  
  String get icon {
    switch (this) {
      case EmergencyType.medical:
        return 'medical_services';
      case EmergencyType.police:
        return 'local_police';
      case EmergencyType.fire:
        return 'local_fire_department';
    }
  }
}
