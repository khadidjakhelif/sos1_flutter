import 'package:sos1/app/app.locator.dart';
import 'package:sos1/services/ai_emergency_assistant.dart';
import 'package:sos1/services/ai_speech_service.dart';
import 'package:sos1/services/ai_tts_service.dart';
import 'package:sos1/services/language_service.dart';
import 'package:sos1/services/medical_profile_service.dart';

void registerManualDependencies() {
  locator
      .registerLazySingleton(() => AISpeechService(locator<LanguageService>()));
  locator.registerLazySingleton(() => AIEmergencyAssistant(
        locator<AITtsService>(),
        locator<LanguageService>(),
        locator<MedicalProfileService>(),
      ));
}
