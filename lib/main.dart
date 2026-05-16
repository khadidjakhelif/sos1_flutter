import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sos1/services/ai_tts_service.dart';
import 'package:sos1/services/api_service.dart';
import 'package:sos1/services/language_service.dart';
import 'package:sos1/utils/app_config.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:provider/provider.dart';
import 'app/app.locator.dart';
import 'app/app.router.dart';
import 'models/language.dart';
import 'utils/app_theme.dart';
import 'utils/app_language_provider.dart';
import 'models/medical_profile.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:home_widget/home_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupLocator();

  // LanguageService (used by AI/TTS)
  await locator<LanguageService>().loadLanguage();

  // LanguageProvider (used by UI)
  final languageProvider = locator<LanguageProvider>();
  await languageProvider.loadLanguage();

  await locator<AITtsService>().initialize();

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

  // Register adapters — order doesn't matter
  Hive.registerAdapter(MedicalProfileAdapter());
  Hive.registerAdapter(ICEContactAdapter());
  Hive.registerAdapter(BloodTypeAdapter());

  // Open the box before the locator so the service can access it
  await Hive.openBox<MedicalProfile>('medicalProfile');

  // Handle widget tap that launched the app
  HomeWidget.setAppGroupId('group.com.example.sos1');

  final apiService = locator<ApiService>();
  final isLoggedIn = await apiService.isLoggedIn();

  runApp(ChangeNotifierProvider.value(
      value: languageProvider, child: SOS1App(isLoggedIn: isLoggedIn)));
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
