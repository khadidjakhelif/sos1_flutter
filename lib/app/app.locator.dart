import 'package:stacked_services/src/navigation/navigation_service.dart';
import 'package:stacked_shared/stacked_shared.dart';

import '../services/ai_emergency_assistant.dart';
import '../services/ai_speech_service.dart';
import '../services/ai_tts_service.dart';
import '../services/contacts_service.dart';
import '../services/language_service.dart';
import '../services/medical_profile_service.dart';
import '../services/sos_history_service.dart';
import '../services/speech_recognition_service.dart';
import '../services/text_to_speech_service.dart';
import '../services/emergency_actions_service.dart';
import '../ui/views/emergency_mode/emergency_mode_viewmodel.dart';
import '../utils/app_language_provider.dart';


final locator = StackedLocator.instance;

Future<void> setupLocator({
  String? environment,
  EnvironmentFilter? environmentFilter,
}) async {
// Register environments
  locator.registerEnvironment(
      environment: environment, environmentFilter: environmentFilter);

// Register dependencies

  locator.registerLazySingleton(() => LanguageService());
  locator.registerLazySingleton(() => LanguageProvider());
  locator.registerLazySingleton(() => NavigationService());
  locator.registerLazySingleton(() => SpeechRecognitionService());
  locator.registerLazySingleton(() => TextToSpeechService());
  locator.registerLazySingleton(() => AITtsService(locator<LanguageService>()));
  locator.registerLazySingleton(() => AISpeechService(
    locator<LanguageService>(),
  ));
  locator.registerLazySingleton(() => AIEmergencyAssistant(
    locator<AITtsService>(),
    locator<LanguageService>(),
    locator<MedicalProfileService>(),
  ));
  locator.registerLazySingleton(() => ContactsService());
  locator.registerLazySingleton(() => MedicalProfileService());
  locator.registerLazySingleton(() => SOSHistoryService());
  locator.registerLazySingleton(() => LanguageService());
  locator.registerLazySingleton(() => LanguageProvider());
  locator.registerLazySingleton(() => EmergencyActionsService());

  // ViewModels get the SAME instances
  locator.registerFactory<EmergencyModeViewModel>(() => EmergencyModeViewModel());
}
