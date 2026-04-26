import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'voice_assistant_viewmodel.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_strings.dart';
import '../../widgets/mic_button.dart';
import '../../widgets/quick_command_button.dart';
import '../../widgets/example_command_text.dart';
import '../../../utils/app_language_provider.dart';
import 'package:provider/provider.dart';

class VoiceAssistantView extends StackedView<VoiceAssistantViewModel> {
  const VoiceAssistantView({super.key});

  @override
  Widget builder(
    BuildContext context,
    VoiceAssistantViewModel viewModel,
    Widget? child,
  ) {
    return Consumer<LanguageProvider>(builder: (context, languageProvider, child)
    {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(viewModel),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: 40.h),

                      // Title Section
                      _buildTitleSection(),

                      SizedBox(height: 50.h),

                      // Microphone Button
                      MicButton(
                        isListening: viewModel.isListening,
                        onTap: viewModel.toggleListening,
                      ),


                      SizedBox(height: 60.h),

                      // Example Command or Recognized Text
                      if (viewModel.userCommand.isEmpty)
                        const ExampleCommandText()
                      else
                        _buildRecognizedText(viewModel.userCommand),

                      SizedBox(height: 30.h),

                      // AI Processing Indicator
                      if (viewModel.isProcessing)
                        _buildAIProcessingIndicator(),

                      // Emergency Response Card
                      if (viewModel.showEmergencyResponse && viewModel.detectedEmergencyType.isNotEmpty)
                        _buildEmergencyResponse(viewModel),

                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),

              // Quick Commands Section
              _buildQuickCommandsSection(viewModel),
            ],
          ),
        ),
      );
    }
    );
  }

  Widget _buildHeader(VoiceAssistantViewModel viewModel) {
    return Consumer<LanguageProvider>(builder: (context, languageProvider, child) {
      return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          // LANGUAGE INDICATOR
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language,
                  color: Colors.white,
                  size: 14.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  viewModel.languageCode.toUpperCase(),  // Shows "FR", "AR", "EN"
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),
          
          // App Title
          Column(
            children: [
              Text(
                languageProvider.translate('app_name'),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryRed,
                  letterSpacing: 2,
                ),
              ),
              Text(
                languageProvider.translate('app_subtitle'),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          
          const Spacer(),

          SizedBox(width: 8.w), // Spacer

          // Settings Button
          GestureDetector(
            onTap: viewModel.navigateToSettings,
            child: Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.settings,
                color: Colors.white,
                size: 22.sp,
              ),
            ),
          ),
        ],
      ),
    );
  });
  }

  Widget _buildTitleSection() {
    return Consumer<LanguageProvider>(builder: (context, languageProvider, child)
      {
        return Column(
          children: [
            // Main Question
            Text(
              languageProvider.translate('how_can_i_help'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),

            SizedBox(height: 12.h),

            // Subtitle
            Text(
              languageProvider.translate('voice_assistant_active'),
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
                letterSpacing: 3,
              ),
            ),
          ],
        );
      });

  }

  Widget _buildRecognizedText(String text) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primaryRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            '"$text"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6.w,
                height: 6.w,
                decoration: const BoxDecoration(
                  color: AppColors.primaryRed,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 4.w),
              Container(
                width: 6.w,
                height: 6.w,
                decoration: const BoxDecoration(
                  color: AppColors.primaryRed,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 4.w),
              Container(
                width: 6.w,
                height: 6.w,
                decoration: const BoxDecoration(
                  color: AppColors.primaryRed,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideY(begin: 0.2, end: 0);
  }

  Widget _buildAIProcessingIndicator() {
    return Consumer<LanguageProvider>(builder: (context, languageProvider, child)
    {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 30.w),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.primaryRed.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              languageProvider.translate('ai_processing'),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ).animate()
          .fadeIn(duration: 300.ms);
    });
  }

  Widget _buildEmergencyResponse(VoiceAssistantViewModel viewModel) {

    final emergencyType = viewModel.detectedEmergencyType;
    final confidence = viewModel.confidenceScore;
    
    return Consumer<LanguageProvider>(builder: (context, languageProvider, child)
    {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 30.w),
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.redGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryRed.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // AI Badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 14.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    languageProvider.translate('ai_used'),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            Icon(
              _getEmergencyIconByType(emergencyType),
              color: Colors.white,
              size: 48.sp,
            ),
            SizedBox(height: 16.h),
            Text(
              _getEmergencyDisplayName(emergencyType, viewModel.languageCode),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),

            // Confidence Score
            Text(
              'Confiance: ${(confidence * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.7),
              ),
            ),

            SizedBox(height: 8.h),
            Text(
              languageProvider.translate('emergency_mode_activated'),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 16.h),

            // Emergency Number
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                _getEmergencyNumber(emergencyType),
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Manual Launch Button
            GestureDetector(
              onTap: () => viewModel.startEmergencyMode(emergencyType),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'LANCER MAINTENANT',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
            ),
          ],
        ),
      ).animate()
          .fadeIn(duration: 400.ms)
          .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1))
          .then()
          .shimmer(duration: 1000.ms, color: Colors.white.withOpacity(0.2));
    });
  }

  IconData _getEmergencyIconByType(String type) {
    final icons = {
      'cardiac': Icons.favorite,
      'medical': Icons.medical_services,
      'bleeding': Icons.water_drop,
      'choking': Icons.air,
      'fire': Icons.local_fire_department,
      'police': Icons.local_police,
      'unconscious': Icons.bed,
    };
    return icons[type.toLowerCase()] ?? Icons.emergency;
  }

  String _getEmergencyDisplayName(String type, String langCode) {
    final names = {
      'fr': {
        'cardiac': 'Urgence Cardiaque',
        'medical': 'Urgence Médicale',
        'bleeding': 'Saignement',
        'choking': 'Étouffement',
        'fire': 'Incendie',
        'police': 'Urgence Police',
        'unconscious': 'Inconscience',
      },
      'ar': {
        'cardiac': 'توقف القلب',
        'medical': 'طوارئ طبية',
        'bleeding': 'نزيف',
        'choking': 'اختناق',
        'fire': 'حريق',
        'police': 'طوارئ أمنية',
        'unconscious': 'فقدان الوعي',
      },
      'en': {
        'cardiac': 'Cardiac Emergency',
        'medical': 'Medical Emergency',
        'bleeding': 'Bleeding',
        'choking': 'Choking',
        'fire': 'Fire',
        'police': 'Police Emergency',
        'unconscious': 'Unconsciousness',
      },
    };
    return names[langCode]?[type.toLowerCase()]
        ?? names['fr']![type.toLowerCase()]
        ?? 'Emergency';
  }

  String _getEmergencyNumber(String type) {
    final numbers = {
      'cardiac': '15',
      'medical': '15',
      'bleeding': '15',
      'choking': '15',
      'fire': '18',
      'police': '17',
      'unconscious': '15',
    };
    return numbers[type.toLowerCase()] ?? '15';
  }

  Widget _buildQuickCommandsSection(VoiceAssistantViewModel viewModel) {
    return Consumer<LanguageProvider>(builder: (context, languageProvider, child)
    {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 24.h),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          children: [
            // Section Title
            Text(
              languageProvider.translate('rapid_calls'),
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 2,
              ),
            ),

            SizedBox(height: 11.h),

            // Quick Command Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                QuickCommandButton(
                  icon: Icons.medical_services,
                  label: languageProvider.translate('samu'),
                  onTap: viewModel.onSamuPressed,
                ),
                QuickCommandButton(
                  icon: Icons.local_police,
                  label: languageProvider.translate('police'),
                  onTap: viewModel.onPolicePressed,
                ),
                QuickCommandButton(
                  icon: Icons.local_fire_department,
                  label: languageProvider.translate('fire_department'),
                  onTap: viewModel.onPompiersPressed,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  @override
  VoiceAssistantViewModel viewModelBuilder(BuildContext context) {
    return VoiceAssistantViewModel();
  }
  
  @override
  void onViewModelReady(VoiceAssistantViewModel viewModel) {
    viewModel.initialize();
  }
}
