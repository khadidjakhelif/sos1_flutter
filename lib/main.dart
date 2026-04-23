import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sos1/utils/app_config.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:provider/provider.dart';
import 'app/app.locator.dart';
import 'app/app.router.dart';
import 'utils/app_theme.dart';
import 'utils/app_language_provider.dart';
import 'models/medical_profile.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Quick test - remove after verifying
  print('API Key loaded: ${AppConfig.geminiApiKey.isNotEmpty ? "✅ YES" : "❌ NO"}');


  // Initialize HiveBox
  await Hive.initFlutter();

  // Register adapters — order doesn't matter
  Hive.registerAdapter(MedicalProfileAdapter());
  Hive.registerAdapter(ICEContactAdapter());
  Hive.registerAdapter(BloodTypeAdapter());

  // Open the box before the locator so the service can access it
  await Hive.openBox<MedicalProfile>('medicalProfile');

  await setupLocator();


  // Initialize LanguageProvider
  final languageProvider = locator<LanguageProvider>();
  await languageProvider.loadLanguage();
  
  runApp(ChangeNotifierProvider.value(
      value: languageProvider,
      child: const SOS1App()));
}

class SOS1App extends StatelessWidget {
  const SOS1App({super.key});

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
          initialRoute: Routes.voiceAssistantView,
          );
        },
        );
      },
    );
  }
}