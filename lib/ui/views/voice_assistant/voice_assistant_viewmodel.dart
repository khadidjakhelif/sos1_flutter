import 'dart:async';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sos1/app/app.locator.dart';
import 'package:sos1/app/app.router.dart';
import 'package:sos1/services/api_service.dart';
import 'package:sos1/services/emergency_sse_service.dart';
import 'package:sos1/services/worker_location_service.dart';
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
  final _apiService = locator<ApiService>();
  final _sseService = locator<EmergencySseService>();
  final _workerLocationService = locator<WorkerLocationService>();

  // Reactive state
  bool get isListening => _aiSpeechService.isListening;
  bool get isProcessing =>
      _aiSpeechService.isProcessing || _aiTtsService.isProcessing;
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
  StreamSubscription? _sseStartedSub;
  StreamSubscription? _sseResolvedSub;

  // Fix 3: "not an emergency" UI state
  bool _isNotEmergency = false;
  String _notEmergencyText = '';
  bool _disposed = false; // guard for delayed callbacks

  bool get isNotEmergency => _isNotEmergency;
  String get notEmergencyText => _notEmergencyText;

  Future<void> initialize() async {
    setBusy(true);

    // Initialize AI services
    await _aiSpeechService.initialize();
    await _aiTtsService.initialize();

    // Fix 1 & 2: Forward TTS state changes to the UI layer
    _aiTtsService.addListener(_onTtsUpdate);

    // Fix 2: Forward speech service state changes (so isListening resets the orb)
    _aiSpeechService.addListener(_onSpeechUpdate);

    // Listen to AI intent detection
    _intentSubscription =
        _aiSpeechService.intentStream.listen(_onEmergencyDetected);

    // Global SSE & Worker Location Setup
    try {
      final token = await _apiService.getToken();
      final companyId = await _apiService.getCompanyId();
      if (token != null && companyId != null) {
        await _sseService.connect(companyId, token);
        
        // Fetch initially active emergencies so we don't miss any that started before we opened the app
        final activeEmergencies = await _apiService.getActiveCompanyEmergencies();
        for (final emg in activeEmergencies) {
          final id = emg['id'] as String?;
          if (id != null) _workerLocationService.start(id);
        }

        _sseStartedSub = _sseService.emergencyStartedStream.listen((id) {
          _workerLocationService.start(id);
        });
        _sseResolvedSub = _sseService.resolutionStream.listen((resolution) {
          _workerLocationService.stop(resolution.emergencyId);
        });
      }
    } catch (e) {
      print('Failed to setup SSE in VoiceAssistant: $e');
    }

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

  /// Fix 1: Forward TTS changes (isSpeaking) to UI
  void _onTtsUpdate() {
    notifyListeners();
  }

  /// Fix 1: Stop TTS playback
  Future<void> stopSpeaking() async {
    await _aiTtsService.stop();
    notifyListeners();
  }

  /// Fix 2 & LIVE SPEECH DISPLAY: Always notify so the orb icon
  /// correctly reflects isListening going false after speech ends.
  void _onSpeechUpdate() {
    if (_aiSpeechService.isListening) {
      _userCommand = _aiSpeechService.recognizedWords.isNotEmpty
          ? _aiSpeechService.recognizedWords
          : _aiSpeechService.lastWords;
    }
    // Always notify — covers isListening → false transition (orb icon fix)
    notifyListeners();
  }

  void _onEmergencyDetected(EmergencyIntent intent) async {
    print('🔥 EMERGENCY DETECTED: ${intent.type} (${intent.confidence})');
    if (intent.isHighConfidence || intent.needsImmediateResponse == true) {
      print('🚨 HIGH CONFIDENCE - Showing UI');
      // Reset "not an emergency" state if a real emergency follows
      _isNotEmergency = false;
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
      // Fix 3: Low-severity / not-an-emergency branch
      print('ℹ️ Low confidence (${intent.confidence}) — sending reassurance');
      _userCommand = intent.rawText;
      _showEmergencyResponse = false;
      _isNotEmergency = true;
      _notEmergencyText = intent.rawText;
      notifyListeners();

      // Speak a localized reassurance message based on current language
      final reassurance = _getReassuranceMessage();
      await _aiTtsService.speak(reassurance);

      // Auto-clear the "not an emergency" card after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (!_disposed) {
          _isNotEmergency = false;
          notifyListeners();
        }
      });
    }

    notifyListeners();
  }

  /// Fix 3: Returns a localized reassurance message
  String _getReassuranceMessage() {
    final messages = {
      'fr': 'Ce n\'est pas une urgence. Restez calme et prudent.',
      'ar': 'هذه ليست حالة طوارئ. ابقَ هادئاً وحذراً.',
      'en': 'This is not an emergency. Stay calm and careful.',
    };
    return messages[languageCode] ?? messages['fr']!;
  }

  Future<void> toggleListening() async {
    try {
      if (_aiSpeechService.isListening) {
        await _aiSpeechService.stopListening();
        _aiSpeechService.playStopBeep();
        // Keep _userCommand showing the final recognized text
      } else {
        // Clear previous state before new session
        _showEmergencyResponse = false;
        _detectedEmergencyType = '';
        _userCommand = ''; // clears so ExampleCommandText shows
        _aiSpeechService.clearRecognizedWords();
        notifyListeners();
        _aiSpeechService.playStartBeep();
        await _aiSpeechService.startListening();
      }
    } catch (e) {
      print('Microphone error: $e');
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
    _isNotEmergency = false;
    _notEmergencyText = '';
    _aiSpeechService.clearRecognizedWords();
    notifyListeners();
  }

  Future<void> goBack() async {
    await _navigationService.back();
  }

  void navigateToSettings() {
    _navigationService.navigateTo(Routes.settingsView);
  }

  void navigateToLanguageSelection() {
    _navigationService.navigateTo(Routes.languageSelectionView);
  }

  @override
  void dispose() {
    _disposed = true; // guard delayed callbacks
    _aiSpeechService.removeListener(_onSpeechUpdate);
    _aiTtsService.removeListener(_onTtsUpdate); // Fix 1
    _intentSubscription?.cancel();
    _sseStartedSub?.cancel();
    _sseResolvedSub?.cancel();
    _workerLocationService.stopAll();
    _sseService.disconnect();
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
