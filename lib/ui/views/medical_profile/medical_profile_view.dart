import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'medical_profile_viewmodel.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_language_provider.dart';
import '../../../models/medical_profile.dart';

class MedicalProfileView extends StackedView<MedicalProfileViewModel> {
  const MedicalProfileView({super.key});

  @override
  Widget builder(
      BuildContext context,
      MedicalProfileViewModel viewModel,
      Widget? child,
      ) {
    return Consumer<LanguageProvider>(
      builder: (context, lp, _) {
        final profile = viewModel.profile;

        // Profile not yet created — prompt user to fill in info
        if (profile == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(viewModel, lp),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_add, color: AppColors.primaryRed, size: 64.sp),
                          SizedBox(height: 16.h),
                          Text(
                            lp.translate('profile_empty_title'),
                            style: TextStyle(fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            lp.translate('profile_empty_subtitle'),
                            style: TextStyle(fontSize: 14.sp, color: AppColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 32.h),
                          GestureDetector(
                            onTap: viewModel.editProfile,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Text(
                                lp.translate('profile_create'),
                                style: TextStyle(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(viewModel, lp),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        SizedBox(height: 24.h),
                        _buildProfileHeader(profile, lp),
                        SizedBox(height: 32.h),
                        _buildBloodTypeCard(profile, lp),
                        SizedBox(height: 32.h),
                        _buildVitalInfoSection(lp),
                        SizedBox(height: 16.h),
                        _buildInfoCard(
                          icon: Icons.monitor_heart,
                          iconColor: AppColors.primaryRed,
                          title: lp.translate('chronic_diseases'),
                          subtitle: profile.chronicDiseases.isEmpty
                              ? lp.translate('none')
                              : profile.chronicDiseases.join(', '),
                          onTap: () {},
                        ),
                        SizedBox(height: 12.h),
                        _buildInfoCard(
                          icon: Icons.warning_amber,
                          iconColor: AppColors.primaryRed,
                          title: lp.translate('allergies'),
                          subtitle: profile.allergies.isEmpty
                              ? lp.translate('none')
                              : profile.allergies.join(', '),
                          subtitleColor: AppColors.primaryRed,
                          onTap: () {},
                        ),
                        SizedBox(height: 12.h),
                        _buildEmergencyNotesCard(profile.emergencyNotes, lp),
                        SizedBox(height: 12.h),
                        if (profile.iceContact != null)
                          _buildICEContactCard(profile.iceContact!, viewModel, lp),
                        SizedBox(height: 32.h),
                        Text(
                          lp.translate('profile_footer'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                            letterSpacing: 1,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        _buildClearProfileButton(viewModel, lp, context),
                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(MedicalProfileViewModel viewModel, LanguageProvider lp) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: viewModel.goBack,
            child: Row(
              children: [
                Icon(Icons.arrow_back_ios, color: Colors.white, size: 20.sp),
                SizedBox(width: 4.w),
                Text(
                  lp.translate('back'),
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            lp.translate('medical_profile'),
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const Spacer(),
          GestureDetector(
            onTap: viewModel.editProfile,
            child: Text(
              lp.translate('edit'),
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(MedicalProfile profile, LanguageProvider lp) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryRed, width: 3),
                image: profile.avatarUrl != null
                    ? DecorationImage(image: NetworkImage(profile.avatarUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: profile.avatarUrl == null
                  ? Center(
                child: Text(
                  profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              )
                  : null,
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Text(
          profile.fullName.isNotEmpty ? profile.fullName : lp.translate('profile_no_name'),
          style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20.r)),
          child: Text(
            'ID: ${profile.sosId}',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ),
        SizedBox(height: 8.h),
        if (profile.lastUpdated != null)
          Text(
            '${lp.translate('last_updated')}: ${_formatDate(profile.lastUpdated!)}',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w400, color: AppColors.textMuted),
          ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildBloodTypeCard(MedicalProfile profile, LanguageProvider lp) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.primaryRed.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Text(
            lp.translate('blood_type'),
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 2),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.bloodType.displayName[0],
                style: TextStyle(fontSize: 64.sp, fontWeight: FontWeight.w800, color: AppColors.primaryRed),
              ),
              Column(
                children: [
                  Text(
                    profile.bloodType.displayName.substring(1),
                    style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.w700, color: AppColors.primaryRed),
                  ),
                  Text(
                    profile.bloodType.displayName.contains('+') ? 'Rh+' : 'Rh-',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: AppColors.primaryRed.withOpacity(0.7)),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (profile.isUniversalDonor)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite, color: AppColors.primaryRed, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text(
                    lp.translate('universal_donor'),
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.primaryRed),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildVitalInfoSection(LanguageProvider lp) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Icon(Icons.monitor_heart, color: AppColors.primaryRed, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            lp.translate('vital_info'),
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color? subtitleColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16.r)),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: iconColor, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w400, color: subtitleColor ?? AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildEmergencyNotesCard(String notes, LanguageProvider lp) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.note_alt, color: AppColors.primaryRed, size: 24.sp),
              ),
              SizedBox(width: 16.w),
              Text(
                lp.translate('emergency_notes'),
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            notes.isNotEmpty ? notes : lp.translate('none'),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildICEContactCard(ICEContact contact, MedicalProfileViewModel viewModel, LanguageProvider lp) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16.r)),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.contact_emergency, color: AppColors.primaryRed, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lp.translate('ice_contact'),
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${contact.name} (${contact.relation})',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
                ),
                Text(
                  contact.phoneNumber,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.primaryRed),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: viewModel.callICEContact,
            child: Container(
              width: 48.w,
              height: 48.w,
              decoration: const BoxDecoration(color: AppColors.primaryRed, shape: BoxShape.circle),
              child: Icon(Icons.phone, color: Colors.white, size: 24.sp),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildClearProfileButton(MedicalProfileViewModel viewModel, LanguageProvider lp, BuildContext context, ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: () => viewModel.clearProfile(context),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 18.h),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.primaryRed.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete, color: AppColors.primaryRed, size: 20.sp),
              SizedBox(width: 12.w),
              Text(
                lp.translate('clear_profile'),
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.primaryRed),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  String _formatDate(DateTime date) {
    final months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  MedicalProfileViewModel viewModelBuilder(BuildContext context) => MedicalProfileViewModel();

  @override
  void onViewModelReady(MedicalProfileViewModel viewModel) => viewModel.initialize();
}