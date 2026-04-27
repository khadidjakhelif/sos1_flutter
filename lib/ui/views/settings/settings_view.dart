import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../utils/app_language_provider.dart';
import 'settings_viewmodel.dart';
import '../../../utils/app_colors.dart';
import 'package:provider/provider.dart';

class SettingsView extends StackedView<SettingsViewModel> {
  const SettingsView({super.key});

  @override
  Widget builder(BuildContext context, SettingsViewModel viewModel, Widget? child,
  ) {
    return Consumer<LanguageProvider>(builder: (context, languageProvider, child) {
      return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(viewModel),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24.h),
                    
                    // Account & Security Section
                    _buildSectionTitle(languageProvider.translate('account_security')),
                    SizedBox(height: 16.h),
                    
                    _buildMenuItem(
                      icon: Icons.medical_services,
                      iconBackgroundColor: AppColors.primaryRed,
                      title: languageProvider.translate('medical_profile'),
                      subtitle: languageProvider.translate('medical_profile_subtitle'),
                      onTap: viewModel.navigateToMedicalProfile,
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    _buildMenuItem(
                      icon: Icons.people,
                      iconBackgroundColor: AppColors.primaryRed,
                      title: languageProvider.translate('emergency_contacts'),
                      subtitle: languageProvider.translate('emergency_contacts_subtitle'),
                      onTap: viewModel.navigateToEmergencyContacts,
                    ),
                    
                    SizedBox(height: 32.h),
                    
                    // App Preferences Section
                    _buildSectionTitle(languageProvider.translate('app_preferences')),
                    SizedBox(height: 16.h),
                    
                    _buildMenuItem(
                      icon: Icons.translate,
                      iconBackgroundColor: const Color(0xFF607D8B),
                      title: languageProvider.translate('language'),
                      subtitle: languageProvider.translate('language_subtitle'),
                      onTap: viewModel.navigateToLanguageSelection,
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    _buildMenuItem(
                      icon: Icons.location_on,
                      iconBackgroundColor: const Color(0xFF607D8B),
                      title: languageProvider.translate('location_sharing'),
                      subtitle: languageProvider.translate('location_sharing_subtitle'),
                      onTap: viewModel.navigateToLocationSharing,
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    _buildMenuItem(
                      icon: Icons.history,
                      iconBackgroundColor: const Color(0xFF607D8B),
                      title: languageProvider.translate('sos_history'),
                      subtitle: languageProvider.translate('sos_history_subtitle'),
                      onTap: viewModel.navigateToSOSHistory,
                    ),

                    SizedBox(height: 12.h),

                    _buildMenuItem(
                      icon: Icons.security,
                      iconBackgroundColor: const Color(0xFF607D8B),
                      title: languageProvider.translate('privacy_policy'),
                      subtitle: languageProvider.translate('privacy_policy_subtitle'),
                      onTap: viewModel.navigateToPrivacyPolicy,
                    ),

                    SizedBox(height: 12.h),

                    _buildMenuItem(
                      icon: Icons.library_books_sharp,
                      iconBackgroundColor: const Color(0xFF607D8B),
                      title: languageProvider.translate('terms_of_use'),
                      subtitle: languageProvider.translate('terms_of_use_subtitle'),
                      onTap: viewModel.navigateToTermsOfUse,
                    ),

                    SizedBox(height: 32.h),
                    
                    // Logout Button
                    _buildLogoutButton(viewModel),
                    
                    SizedBox(height: 48.h),
                    
                    // Footer
                    _buildFooter(viewModel,languageProvider),
                    
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  });
  }

  Widget _buildHeader(SettingsViewModel viewModel) {
    return Consumer<LanguageProvider>(builder: (context, languageProvider, child) {
     return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: viewModel.goBack,
            child: Row(
              children: [
                Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  languageProvider.translate('back'),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            languageProvider.translate('settings'),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          SizedBox(width: 80.w),
        ],
      ),
    );
  });
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Text(
        key: ValueKey(title),
        title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBackgroundColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: ValueKey(title),
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow
            Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 24.sp,
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideX(begin: 0.1, end: 0);
  }

  Widget _buildLogoutButton(SettingsViewModel viewModel) {
    return Consumer<LanguageProvider>(builder: (context, languageProvider, child) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: viewModel.logout,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 18.h),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.primaryRed,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout,
                color: AppColors.primaryRed,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                languageProvider.translate('logout'),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryRed,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  });
  }

  Widget _buildFooter(SettingsViewModel viewModel, LanguageProvider languageProvider) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${languageProvider.translate('app_name')}: ${viewModel.appVersion}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '${languageProvider.translate('emergency_number')}: ${viewModel.emergencyNumber}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 16.h),
          // Home indicator
          Container(
            width: 134.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(3.r),
            ),
          ),
        ],
      ),
    );
  }

  @override
  SettingsViewModel viewModelBuilder(BuildContext context) => SettingsViewModel();

  @override
  void onViewModelReady(SettingsViewModel viewModel) => viewModel.initialize();
}
