import 'package:sos1/app/app.locator.dart';
import 'package:sos1/services/ai_emergency_assistant.dart';
import 'package:sos1/services/ai_speech_service.dart';
import 'package:sos1/services/ai_tts_service.dart';
import 'package:sos1/services/api_service.dart';
import 'package:sos1/services/emergency_heartbeat_service.dart';
import 'package:sos1/services/language_service.dart';
import 'package:sos1/services/location_tracking_service.dart';
import 'package:sos1/services/medical_profile_service.dart';
import 'package:sos1/services/worker_location_service.dart';

void registerManualDependencies() {
  locator
      .registerLazySingleton(() => AISpeechService(locator<LanguageService>()));
  locator.registerLazySingleton(() => AIEmergencyAssistant(
        locator<AITtsService>(),
        locator<LanguageService>(),
        locator<MedicalProfileService>(),
      ));
  // Live location tracker — started on login, stopped on logout
  locator.registerLazySingleton(() => LocationTrackingService());

  // NEW: heartbeat service depends on ApiService (already registered)
  locator.registerLazySingleton(
    () => EmergencyHeartbeatService(locator<ApiService>()),
  );
  locator.registerLazySingleton(
    () => WorkerLocationService(locator<ApiService>()),
  );
}

