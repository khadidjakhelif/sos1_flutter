import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sos1/services/speech_recognition_service.dart';
import 'package:sos1/services/text_to_speech_service.dart';
import 'package:sos1/services/ai_tts_service.dart';
import 'package:sos1/services/ai_speech_service.dart';
import 'package:sos1/services/ai_emergency_assistant.dart';
import 'package:sos1/services/contacts_service.dart';
import 'package:sos1/services/medical_profile_service.dart';
import 'package:sos1/services/sos_history_service.dart';
import 'package:sos1/services/language_service.dart';
import 'package:sos1/ui/views/voice_assistant/voice_assistant_view.dart';
import 'package:sos1/ui/views/emergency_contacts/emergency_contacts_view.dart';
import 'package:sos1/ui/views/medical_profile/medical_profile_view.dart';
import 'package:sos1/ui/views/language_selection/language_selection_view.dart';
import 'package:sos1/ui/views/settings/settings_view.dart';
import 'package:sos1/ui/views/sos_history/sos_history_view.dart';
import 'package:sos1/ui/views/emergency_mode/emergency_mode_view.dart';

import '../utils/app_language_provider.dart';

@StackedApp(
  routes: [
    MaterialRoute(page: VoiceAssistantView, initial: true),
    MaterialRoute(page: EmergencyContactsView),
    MaterialRoute(page: MedicalProfileView),
    MaterialRoute(page: LanguageSelectionView),
    MaterialRoute(page: SettingsView),
    MaterialRoute(page: SOSHistoryView),
    MaterialRoute(page: EmergencyModeView),
  ],
  dependencies: [
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: SpeechRecognitionService),
    LazySingleton(classType: TextToSpeechService),
    LazySingleton(classType: AITtsService),
    LazySingleton(classType: AISpeechService),
    LazySingleton(classType: AIEmergencyAssistant),
    LazySingleton(classType: ContactsService),
    LazySingleton(classType: MedicalProfileService),
    LazySingleton(classType: SOSHistoryService),
    LazySingleton(classType: LanguageService),
    LazySingleton(classType: LanguageProvider),
  ],
)
class App {}
