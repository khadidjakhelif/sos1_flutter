import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'voice_assistant_viewmodel.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_strings.dart';
import '../../../utils/app_language_provider.dart';
import '../../widgets/sos_orb.dart';

class VoiceAssistantView extends StackedView<VoiceAssistantViewModel> {
  const VoiceAssistantView({super.key});

  @override
  Widget builder(
    BuildContext context,
    VoiceAssistantViewModel viewModel,
    Widget? child,
  ) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Minimal Header
                _buildHeader(viewModel, languageProvider),

                // Main Content — the orb
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Show recognized text above orb when there's speech
                      if (viewModel.userCommand.isNotEmpty)
                        _buildRecognizedText(viewModel.userCommand),

                      // The 3D Orb
                      SosOrb(
                        isListening: viewModel.isListening,
                        isProcessing: viewModel.isProcessing,
                        onTap: viewModel.toggleListening,
                      ),

                      // Emergency Response Card
                      if (viewModel.showEmergencyResponse &&
                          viewModel.detectedEmergencyType.isNotEmpty)
                        _buildEmergencyResponse(viewModel, languageProvider),
                    ],
                  ),
                ),

                // Quick Commands at bottom
                _buildQuickCommands(viewModel, languageProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // HEADER — minimal, no back button
  // ─────────────────────────────────────────
  Widget _buildHeader(VoiceAssistantViewModel viewModel, LanguageProvider languageProvider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        children: [
          // App branding
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              SizedBox(height: 2.h),
              Text(
                languageProvider.translate('app_subtitle'),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Language indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              viewModel.languageCode.toUpperCase(),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          SizedBox(width: 10.w),

          // Settings
          GestureDetector(
            onTap: viewModel.navigateToSettings,
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.settings_outlined,
                color: AppColors.textMuted,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // RECOGNIZED TEXT — shown above orb
  // ─────────────────────────────────────────
  Widget _buildRecognizedText(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Text(
        '"$text"',
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.1, end: 0);
  }

  // ─────────────────────────────────────────
  // EMERGENCY RESPONSE — card below orb
  // ─────────────────────────────────────────
  Widget _buildEmergencyResponse(VoiceAssistantViewModel viewModel, LanguageProvider languageProvider) {
    final emergencyType = viewModel.detectedEmergencyType;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 30.w),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.redGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withOpacity(0.35),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  _getEmergencyIcon(emergencyType),
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getEmergencyDisplayName(emergencyType, viewModel.languageCode),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      languageProvider.translate('emergency_mode_activated'),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Manual Launch
          GestureDetector(
            onTap: () => viewModel.startEmergencyMode(emergencyType),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(
                  'LANCER MAINTENANT',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryRed,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0)
        .then()
        .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.15));
  }

  // ─────────────────────────────────────────
  // QUICK COMMANDS — bottom bar
  // ─────────────────────────────────────────
  Widget _buildQuickCommands(VoiceAssistantViewModel viewModel, LanguageProvider languageProvider) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.4),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.r),
          topRight: Radius.circular(28.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            languageProvider.translate('rapid_calls'),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickAction(
                Icons.medical_services_rounded,
                languageProvider.translate('samu'),
                viewModel.onSamuPressed,
              ),
              _buildQuickAction(
                Icons.shield_rounded,
                languageProvider.translate('police'),
                viewModel.onPolicePressed,
              ),
              _buildQuickAction(
                Icons.local_fire_department_rounded,
                languageProvider.translate('fire_department'),
                viewModel.onPompiersPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96.w,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.surfaceLight.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryRed, size: 26.sp),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────
  IconData _getEmergencyIcon(String type) {
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

  @override
  VoiceAssistantViewModel viewModelBuilder(BuildContext context) {
    return VoiceAssistantViewModel();
  }

  @override
  void onViewModelReady(VoiceAssistantViewModel viewModel) {
    viewModel.initialize();
  }
}
