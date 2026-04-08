import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'language_selection_viewmodel.dart';
import '../../../utils/app_colors.dart';
import '../../../models/language.dart';
import '../../../utils/app_language_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSelectionView extends StackedView<LanguageSelectionViewModel> {
  const LanguageSelectionView({super.key});

  @override
  Widget builder(BuildContext context, LanguageSelectionViewModel viewModel, Widget? child,) {
    return Consumer<LanguageProvider>(builder: (context, languageProvider, child) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(viewModel, languageProvider),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: [

                      SizedBox(height: 24.h),

                      // Language Title
                      Text(
                        languageProvider.translate('language'),
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // Red underline
                      Container(
                        width: 80.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),

                      SizedBox(height: 60.h),

                      // French Option
                      _buildLanguageOption(
                        language: AppLanguage.french,
                        isSelected: viewModel.isFrench,
                        onTap: () => viewModel.selectLanguage(AppLanguage.french),
                      ),

                      SizedBox(height: 20.h),

                      // Arabic Option
                      _buildLanguageOption(
                        language: AppLanguage.arabic,
                        isSelected: viewModel.isArabic,
                        onTap: () => viewModel.selectLanguage(AppLanguage.arabic),
                      ),

                      SizedBox(height: 20.h),

                      // English Option
                      _buildLanguageOption(
                        language: AppLanguage.english,
                        isSelected: viewModel.isEnglish,
                        onTap: () => viewModel.selectLanguage(AppLanguage.english),
                      ),

                      SizedBox(height: 60.h),

                      // Continue Button
                      _buildContinueButton(viewModel, languageProvider),

                      SizedBox(height: 10,),
                      // Footer
                      _buildFooter(languageProvider),

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

  Widget _buildHeader(LanguageSelectionViewModel viewModel, LanguageProvider languageProvider) {
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
            languageProvider.translate('app_name'),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          SizedBox(width: 80.w),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required AppLanguage language,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: EdgeInsets.symmetric(horizontal: 40.w),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.surface
                    : AppColors.surface.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected ? AppColors.primaryRed : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: language == AppLanguage.arabic
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.displayName,
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        isSelected
                            ? languageProvider.translate('selected')
                            : '',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color:
                          isSelected ? AppColors.primaryRed : AppColors
                              .textMuted,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryRed : Colors
                          .transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                        isSelected ? AppColors.primaryRed : AppColors.textMuted,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18.sp,
                    )
                        : null,
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(
              duration: 400.ms,
              delay: language == AppLanguage.french ? 100.ms : 200.ms)
              .slideX(begin: 0.2, end: 0);
        }
    );
  }

  Widget _buildContinueButton(LanguageSelectionViewModel viewModel, LanguageProvider languageProvider) {
    return Consumer<LanguageProvider>(builder: (context, languageProvider, child) {
     return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: GestureDetector(
        onTap: () async {
          // Update the provider with the selected language to trigger translation refresh
          await languageProvider.setLanguage(viewModel.selectedLanguage.key );
          // Then continue to the app
          viewModel.continueToApp();
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 20.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.redGradient,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryRed.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            languageProvider.translate('next').toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.2, end: 0);
    });
  }

  Widget _buildFooter(LanguageProvider languageProvider) {
    return Consumer<LanguageProvider>(builder: (context, languageProvider, child) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shield,
                color: AppColors.primaryRed,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                languageProvider.translate('life_critical_emergency_service').toUpperCase(),
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            languageProvider.translate('Algerian_Democratic_and_Popular_Republic').toUpperCase(),
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted.withOpacity(0.7),
              letterSpacing: 1,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
    }
      );
  }

  @override
  LanguageSelectionViewModel viewModelBuilder(BuildContext context) =>
      LanguageSelectionViewModel();

  @override
  void onViewModelReady(LanguageSelectionViewModel viewModel) {}
}
