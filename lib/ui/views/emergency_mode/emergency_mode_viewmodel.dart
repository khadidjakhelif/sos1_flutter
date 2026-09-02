import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:sos1/models/emergency_history.dart';
import 'package:sos1/models/emergency_resolution.dart';
import 'package:sos1/models/language.dart';
import 'package:sos1/models/ping_event.dart'; // NEW
import 'package:sos1/services/api_service.dart';
import 'package:sos1/services/emergency_heartbeat_service.dart'; // NEW
import 'package:sos1/services/emergency_sse_service.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'package:url_launcher/url_launcher.dart';

/// Dispatch status exposed to the view via [EmergencyModeViewModel.reportStatus].
enum EmergencyReportStatus { pending, success, failed }

class EmergencyModeViewModel extends BaseViewModel {
  final _aiAssistant = locator<AIEmergencyAssistant>();
  final _aiTts = locator<AITtsService>();
  final _historyService = locator<SOSHistoryService>();
  final _navigationService = locator<NavigationService>();
  final _languageService = locator<LanguageService>();
  final _emergencyActions = locator<EmergencyActionsService>();
  final _sseService = locator<EmergencySseService>(); // NEW
  final _apiService = locator<ApiService>(); // NEW (moved from local var)
  final _heartbeatService = locator<EmergencyHeartbeatService>(); // NEW

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool get isListening => _isListening;

  // ── NEW: SSE-driven resolution state ─────────────────────────────────────
  EmergencyResolution? _resolution;
  EmergencyResolution? get resolution => _resolution; // consumed by the view
  StreamSubscription<EmergencyResolution>? _resolutionSub; // NEW
  Timer? _messagePollTimer; // NEW: poll backend for officer/system messages

  // ── NEW: Ping state ───────────────────────────────────────────────────────
  PingEvent? _pendingPing;
  PingEvent? get pendingPing => _pendingPing;
  StreamSubscription<PingEvent>? _pingSub; // NEW

  // ── Reactive state (UNCHANGED) ───────────────────────────────────────
  bool get isProcessing => _aiAssistant.isProcessing;
  List<ChatMessage> get messages => _aiAssistant.messages;
  String get currentStep => _aiAssistant.currentStep;
  int get currentStepIndex => _aiAssistant.currentStepIndex;
  bool get isEmergencyActive => _aiAssistant.isEmergencyActive;
  bool get isSpeaking => _aiTts.isSpeaking;

  Future<void> stopSpeaking() async {
    await _aiTts.stop();
    notifyListeners();
  }

  // ── Emergency info (UNCHANGED) ────────────────────────────────────────
  String _emergencyType = '';
  String _emergencyDescription = '';
  String? _userLocation;
  DateTime _emergencyStartTime = DateTime.now();
  // NEW: cached IDs for SSE subscription
  String? _emergencyId;
  String? _companyId;
  String? _primaryOfficerPhone;
  String? get primaryOfficerPhone => _primaryOfficerPhone;
  String? get emergencyId => _emergencyId;

  String get emergencyType => _emergencyType;
  String get emergencyDescription => _emergencyDescription;
  String? get userLocation => _userLocation;

  Timer? _elapsedTimer;
  final ReactiveValue<Duration> _elapsedTime =
      ReactiveValue<Duration>(Duration.zero);
  Duration get elapsedTime => _elapsedTime.value;

  // ── Dispatch status (retry-with-backoff) ─────────────────────────────────
  final ReactiveValue<EmergencyReportStatus> _reportStatus =
      ReactiveValue<EmergencyReportStatus>(EmergencyReportStatus.pending);
  EmergencyReportStatus get reportStatus => _reportStatus.value;

  // ── Auto-call countdown (shown when dispatch fails) ───────────────────────
  Timer? _countdownTimer;
  final ReactiveValue<int?> _countdownSeconds = ReactiveValue<int?>(null);

  /// Non-null while the auto-call countdown is running (value = seconds left).
  int? get countdownSeconds => _countdownSeconds.value;

  /// The emergency number the countdown will dial.
  String? _pendingCallNumber;
  String? get pendingCallNumber => _pendingCallNumber;

  final TextEditingController textController = TextEditingController();

  String get currentLanguage => _languageService.currentLanguage.displayName;
  String get languageCode => _languageService.currentLanguage.code;

  String get stopReadingText {
    final Map<String, String> translations = {
      'fr': 'Arrêter la lecture',
      'en': 'Stop Reading',
      'ar': 'إيقاف القراءة'
    };
    return translations[languageCode] ?? 'Arrêter la lecture';
  }

  @override
  void dispose() {
    _speech.cancel();
    textController.dispose();
    _elapsedTimer?.cancel();
    _countdownTimer?.cancel();
    _resolutionSub?.cancel();
    _pingSub?.cancel(); // NEW
    _heartbeatService.stop(); // NEW — stop GPS immediately on dispose
    _sseService.disconnect();
    _aiTts.removeListener(_onTtsUpdate);
    _messagePollTimer?.cancel();
    _aiAssistant.onMessageAdded = null;
    super.dispose();
  }

  String get formattedElapsedTime {
    final minutes = _elapsedTime.value.inMinutes.toString().padLeft(2, '0');
    final seconds =
        (_elapsedTime.value.inSeconds % 60).toString().padLeft(2, '0');
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
    _aiTts.addListener(_onTtsUpdate);

    _emergencyType = emergencyType;
    _emergencyDescription = emergencyDescription ?? '';

    double? reportLat;
    double? reportLng;

    if (location != null && location.isNotEmpty) {
      _userLocation = location;
    } else {
      final pos = _emergencyActions.lastKnownPosition;
      if (pos != null) {
        _userLocation =
            '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
        reportLat = pos.latitude;
        reportLng = pos.longitude;
      } else {
        _userLocation = 'Position GPS en attente';
      }
    }

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

    // Report to backend — retry with exponential backoff (2 s → 4 s → 8 s)
    await _reportWithRetry(
      emergencyType: emergencyType,
      reportLat: reportLat,
      reportLng: reportLng,
    );

    setBusy(false);
  }

  // ── Retry-with-backoff ────────────────────────────────────────────────────
  Future<void> _reportWithRetry({
    required String emergencyType,
    double? reportLat,
    double? reportLng,
  }) async {
    const maxAttempts = 3;
    final delays = [2, 4, 8]; // seconds

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final response = await _apiService.reportEmergency(
          type: emergencyType,
          severity: 'Critical',
          latitude: reportLat,
          longitude: reportLng,
          locationDescription: _userLocation,
          voiceTranscript:
              _emergencyDescription.isNotEmpty ? _emergencyDescription : null,
        );
        // Success — capture IDs and connect SSE
        if (response != null) {
          _emergencyId = response['id'] as String?;
          _companyId = response['company_id'] as String?;
          _primaryOfficerPhone = response['primary_officer_phone'] as String?;
          if (_companyId != null) await _connectSse();
          // NEW: start GPS heartbeat now that we have an emergency ID
          if (_emergencyId != null) {
            _heartbeatService.start(_emergencyId!);
            _aiAssistant.onMessageAdded = (message) {
              _apiService.sendTextMessageWithRole(
                _emergencyId!,
                message.text,
                message.senderRole,
              ); // fire-and-forget, no await
            };
            // Start polling for officer messages every 5s
            _startMessagePolling();
          }
        }
        _reportStatus.value = EmergencyReportStatus.success;
        notifyListeners();
        return;
      } catch (e) {
        print('[Dispatch] Attempt ${attempt + 1} failed: $e');
        if (attempt < maxAttempts - 1) {
          await Future.delayed(Duration(seconds: delays[attempt]));
        }
      }
    }

    // All retries exhausted — go offline-first + auto-call
    _reportStatus.value = EmergencyReportStatus.failed;
    notifyListeners();
    _startAutoCallCountdown(emergencyType);
  }

  /// Starts a 3-second visible countdown; on expiry opens the phone dialler.
  void _startAutoCallCountdown(String emergencyType) {
    _pendingCallNumber = _getEmergencyNumber(emergencyType);
    _countdownSeconds.value = 3;
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      final current = _countdownSeconds.value;
      if (current == null || current <= 1) {
        t.cancel();
        _countdownSeconds.value = null;
        notifyListeners();
        await _dialNumber(_pendingCallNumber!);
      } else {
        _countdownSeconds.value = current - 1;
        notifyListeners();
      }
    });
  }

  /// Poll backend messages every 5 seconds to receive officer messages
  void _startMessagePolling() {
    _messagePollTimer?.cancel();
    _messagePollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_emergencyId == null) return;
      try {
        final backendMessages = await _apiService.getMessages(_emergencyId!);
        for (final msgJson in backendMessages) {
          final chatMsg = ChatMessage.fromBackend(msgJson);
          final isNew = _aiAssistant.addBackendMessage(chatMsg);
          // If this is a new officer message, inject it into AI context
          if (isNew && chatMsg.senderRole == 'safety_officer') {
            _aiAssistant.injectOfficerMessage(chatMsg.text);
            // Read it aloud via TTS
            _aiTts.speak(chatMsg.text, urgent: true, interrupt: false);
          }
        }
      } catch (e) {
        print('[EmergencyModeViewModel] Message poll failed: $e');
      }
    });
  }

  /// Cancels the auto-call countdown without placing the call.
  void cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _countdownSeconds.value = null;
    _pendingCallNumber = null;
    notifyListeners();
  }

  /// Opens the phone dialler pre-filled with [number] (does NOT auto-dial).
  Future<void> _dialNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('[Dispatch] Could not open dialler for $number');
    }
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

  void _onTtsUpdate() {
    notifyListeners();
  }

  // NEW: connect to the SSE stream and listen for EMERGENCY_RESOLVED events
  Future<void> _connectSse() async {
    try {
      final token = await _apiService.getToken();
      if (token == null || _companyId == null) return;

      await _sseService.connect(_companyId!, token);

      _resolutionSub = _sseService.resolutionStream.listen((resolution) {
        // Only react to events targeting our specific emergency
        if (_emergencyId != null && resolution.emergencyId != _emergencyId) {
          return;
        }

        _resolution = resolution;
        notifyListeners(); // triggers _buildResolutionBanner in the view
        print('[EmergencyModeViewModel] Resolution received: '
            '${resolution.responderType} ETA=${resolution.etaMinutes}min');

        // Trigger TTS to read the banner aloud
        _speakResolutionBanner(resolution);
      });

      // NEW: subscribe to incoming pings from the officer
      _pingSub = _sseService.pingSentStream.listen((ping) {
        if (_emergencyId != null && ping.emergencyId != _emergencyId) return;
        _pendingPing = ping;
        notifyListeners();
        print('[EmergencyModeViewModel] Ping received from officer');
      });
    } catch (e) {
      print('[EmergencyModeViewModel] SSE connect failed: $e'); // silent fail
    }
  }

  Future<void> _speakResolutionBanner(EmergencyResolution resolution) async {
    final langCode = _languageService.currentLanguage.code;

    // The model's responderLabel includes emojis (e.g. "🚓 Police").
    // TTS engines usually handle common emojis well, or we can just use the raw type.
    // We'll strip the emoji by using the raw type translated, or relying on TTS fallback.
    final responderMap = {
      'police': {'fr': 'la police', 'ar': 'الشرطة', 'en': 'the police'},
      'samu': {'fr': 'le SAMU', 'ar': 'الإسعاف', 'en': 'medical services'},
      'fire': {
        'fr': 'les pompiers',
        'ar': 'الحماية المدنية',
        'en': 'the fire department'
      },
      'other': {
        'fr': 'les secours',
        'ar': 'فرق الإنقاذ',
        'en': 'emergency services'
      },
    };

    final rawType = resolution.responderType ?? 'other';
    final responderStr =
        responderMap[rawType]?[langCode] ?? responderMap['other']![langCode]!;

    String textToSpeak = '';

    if (langCode == 'fr') {
      textToSpeak =
          'Les secours ont été confirmés. $responderStr est en route.';
      if (resolution.etaMinutes != null) {
        textToSpeak +=
            ' Arrivée estimée dans ${resolution.etaMinutes} minutes.';
      }
      textToSpeak +=
          ' Vous pouvez arrêter l\'urgence maintenant, ou continuer à parler avec l\'assistant.';
    } else if (langCode == 'ar') {
      textToSpeak = 'تم تأكيد طلب المساعدة. $responderStr في الطريق.';
      if (resolution.etaMinutes != null) {
        textToSpeak += ' الوقت المقدر للوصول ${resolution.etaMinutes} دقائق.';
      }
      textToSpeak +=
          ' يمكنك إيقاف حالة الطوارئ الآن، أو متابعة التحدث مع المساعد.';
    } else {
      textToSpeak =
          'Emergency services confirmed. $responderStr is on the way.';
      if (resolution.etaMinutes != null) {
        textToSpeak +=
            ' Estimated arrival in ${resolution.etaMinutes} minutes.';
      }
      textToSpeak +=
          ' You can stop the emergency now, or continue talking to the assistant.';
    }

    // Call the existing TTS provider without interrupting ongoing AI instructions
    await _aiTts.speak(textToSpeak, urgent: true, interrupt: false);
  }

  Future<void> toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
      _sendTranscript();
    } else {
      _isListening = true;
      print(
          '🎤 Toggle listening - Language: ${_languageService.currentLanguage.code}');
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
        localeId: _getLocaleId(), // get app language
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
      if (_isListening) {
        await _speech.stop();
        _isListening = false;
        notifyListeners();
      }
      print('📤 [1] sendMessage START: "$trimmed"');
      // Also persist worker message to backend fire-and-forget
      if (_emergencyId != null) {
        _apiService.sendTextMessageWithRole(_emergencyId!, trimmed, 'worker');
      }
      await _aiAssistant.processUserMessage(
          trimmed, _languageService.getLanguageCode());
      print('📤 [3] AI processing COMPLETE');
      notifyListeners();
      print('📤 [4] UI notified');
    }
  }

  String _getEmergencyNumber(String type) {
    final numbers = {
      'cardiac': '14',
      'medical': '14',
      'bleeding': '14',
      'choking': '14',
      'unconscious': '14',
      'fire': '14',
      'police': '17',
    };
    return numbers[type.toLowerCase()] ?? '14';
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
        }[langCode] ??
        "Sending SMS alerts and calling emergency services.";

    await _aiTts.speak(confirmation, urgent: true);

    // Trigger full SOS: SMS to all contacts + auto-call first contact
    await _emergencyActions.triggerFullSOS(
      emergencyType: _emergencyType,
      customMessage: _emergencyDescription,
    );
  }

  Future<void> callOfficer() async {
    if (_primaryOfficerPhone != null) {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: _primaryOfficerPhone,
      );
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        print('Could not launch $_primaryOfficerPhone');
      }
    }
  }

  Future<void> shareLocation() async {
    final langCode = _languageService.currentLanguage.code;
    final message = {
          'fr': "Partage de votre position GPS avec les secours.",
          'ar': "مشاركة موقع GPS الخاص بك مع خدمات الإنقاذ.",
          'en': "Sharing your GPS location with emergency services.",
        }[langCode] ??
        "Sharing your location.";

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
    _heartbeatService
        .stop(); // NEW — stop GPS immediately when worker ends emergency

    // Save to history
    await _saveToHistory();

    // End AI session
    await _aiAssistant.endEmergencySession();

    // Navigate back
    _navigationService.back();
  }

  /// NEW: Worker acknowledges the "are you OK?" ping from the officer.
  Future<void> acknowledgePing() async {
    final id = _emergencyId;
    if (id == null) {
      print(
          '[EmergencyModeViewModel] acknowledgePing: _emergencyId is null, cannot ack');
      return;
    }
    _pendingPing = null; // clear prompt immediately for responsiveness
    notifyListeners();
    final success = await _apiService.acknowledgePing(id);
    print(
        '[EmergencyModeViewModel] acknowledgePing result: $success for emergency $id');
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

    await _historyService
        .addIncident(EmergencyHistory.fromSOSIncident(incident));
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
