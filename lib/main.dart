import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sos1/app/app.locator.manual.dart';
import 'package:sos1/services/ai_tts_service.dart';
import 'package:sos1/services/api_service.dart';
import 'package:sos1/services/language_service.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:provider/provider.dart';
import 'app/app.locator.dart';
import 'app/app.router.dart';
import 'models/language.dart';
import 'utils/app_theme.dart';
import 'utils/app_language_provider.dart';
import 'models/medical_profile.dart';
import 'models/emergency_history.dart';
import 'package:sos1/services/medical_profile_service.dart';
import 'package:sos1/services/emergency_actions_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('CP1: binding ready');

  // Initialize Stacked services

  await setupLocator();
  print('CP2: locator setup');

  registerManualDependencies();
  print('CP3: manual deps registered');

  // LanguageService (used by AI/TTS)
  await locator<LanguageService>().loadLanguage();
  print('CP4: language service loaded');

  // LanguageProvider (used by UI)
  final languageProvider = locator<LanguageProvider>();
  await languageProvider.loadLanguage();
  print('CP5: language provider loaded');

  // Sync LanguageService from LanguageProvider's saved value
  final savedLang = locator<LanguageProvider>().currentLanguage;
  final langMap = {
    'Francais': AppLanguage.french,
    'العربية': AppLanguage.arabic,
    'English': AppLanguage.english
  };
  await locator<LanguageService>()
      .setLanguage(langMap[savedLang] ?? AppLanguage.french);

  // Initialize HiveBox
  await Hive.initFlutter();
  print('CP6: hive init');

  // Register adapters — order doesn't matter
  Hive.registerAdapter(MedicalProfileAdapter());
  print('CP7: medical profile adapter');
  Hive.registerAdapter(ICEContactAdapter());
  print('CP8: ICECOntactAdapter');
  Hive.registerAdapter(BloodTypeAdapter());
  print('CP9: Blood type adapter');
  Hive.registerAdapter(EmergencyHistoryAdapter());
  print('CP10: emergency history adapter');

  // Open the box before the locator so the service can access it
  await Hive.openBox<MedicalProfile>('medicalProfile');
  print('CP11: medical profile box opened');

  // Load saved medical profile into memory
  await locator<MedicalProfileService>().initialize();
  print('CP12: medical profile loaded');

  // Handle widget tap that launched the app
  HomeWidget.setAppGroupId('group.com.example.sos1');

  final apiService = locator<ApiService>();
  bool isLoggedIn = false;
  try {
    isLoggedIn = await apiService.isLoggedIn().timeout(
          const Duration(seconds: 5),
          onTimeout: () => false,
        );
    print('CP13: logged in checked');
  } catch (e) {
    print('isLoggedIn check failed: $e');
    isLoggedIn = false;
  }

  runApp(ChangeNotifierProvider.value(
      value: languageProvider, child: SOS1App(isLoggedIn: isLoggedIn)));

  // ── Background inits (must NOT block runApp) ──────────────────────────────
  // TTS engine init and GPS permission/warm-up are slow and involve OS dialogs.
  // Fire them after the first frame so the app is already visible.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    await locator<AITtsService>().initialize();
    await locator<EmergencyActionsService>().initialize();
    
    // Initialize Firebase
    try {
      await Firebase.initializeApp();
      
      // Request permission
      await FirebaseMessaging.instance.requestPermission();
      
      // Sync FCM token if logged in
      if (isLoggedIn) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await apiService.registerFcmToken(token, 'Flutter App');
        }
        
        // Listen to token refresh
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          apiService.registerFcmToken(newToken, 'Flutter App');
        });
      }
    } catch (e) {
      print('Firebase initialization failed: $e');
    }
  });
}

class SOS1App extends StatefulWidget {
  final bool isLoggedIn;
  SOS1App({super.key, required this.isLoggedIn});

  @override
  State<SOS1App> createState() => _SOS1AppState();
}

class _SOS1AppState extends State<SOS1App> {
  @override
  void initState() {
    super.initState();
    _checkWidgetLaunch();
  }

  Future<void> _checkWidgetLaunch() async {
    // Wait for navigator to be ready
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if app was cold-launched from widget tap
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri != null) {
      _navigateToEmergency();
    }

    // Listen for widget taps while app is already running in background
    HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) _navigateToEmergency();
    });
  }

  void _navigateToEmergency() {
    locator<NavigationService>().navigateToEmergencyModeView(
      emergencyType: 'medical',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return MaterialApp(
              title: 'SOS1 - Emergency Voice Assistant',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.darkTheme,
              navigatorKey: StackedService.navigatorKey,
              onGenerateRoute: StackedRouter().onGenerateRoute,
              initialRoute: widget.isLoggedIn
                  ? Routes.voiceAssistantView
                  : Routes.loginView,
            );
          },
        );
      },
    );
  }
}
