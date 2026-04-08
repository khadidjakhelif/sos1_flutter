import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'medical_profile_viewmodel.dart';
import '../../../utils/app_colors.dart';
import '../../../models/medical_profile.dart';

class MedicalProfileView extends StackedView<MedicalProfileViewModel> {
  const MedicalProfileView({super.key});

  @override
  Widget builder(
    BuildContext context,
    MedicalProfileViewModel viewModel,
    Widget? child,
  ) {
    final profile = viewModel.profile;
    if (profile == null) return const SizedBox.shrink();

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
                  children: [
                    SizedBox(height: 24.h),
                    
                    // Profile Header
                    _buildProfileHeader(profile),
                    
                    SizedBox(height: 32.h),
                    
                    // Blood Type Card
                    _buildBloodTypeCard(profile),
                    
                    SizedBox(height: 32.h),
                    
                    // Vital Information Section
                    _buildVitalInfoSection(),
                    
                    SizedBox(height: 16.h),
                    
                    // Chronic Diseases
                    _buildInfoCard(
                      icon: Icons.monitor_heart,
                      iconColor: AppColors.primaryRed,
                      title: 'Maladies Chroniques',
                      subtitle: profile.chronicDiseases.join(', '),
                      onTap: () {},
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    // Allergies
                    _buildInfoCard(
                      icon: Icons.warning_amber,
                      iconColor: AppColors.primaryRed,
                      title: 'Allergies',
                      subtitle: profile.allergies.join(', '),
                      subtitleColor: AppColors.primaryRed,
                      onTap: () {},
                    ),
                    
                    SizedBox(height: 12.h),
                    
                    // Emergency Notes
                    _buildEmergencyNotesCard(profile.emergencyNotes),
                    
                    SizedBox(height: 12.h),
                    
                    // ICE Contact
                    if (profile.iceContact != null)
                      _buildICEContactCard(profile.iceContact!, viewModel),
                    
                    SizedBox(height: 32.h),
                    
                    // Footer Text
                    Text(
                      'CES INFORMATIONS SONT DESTINÉES AUX\nSERVICES DE SECOURS UNIQUEMENT.',
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
                    
                    // Download PDF Button
                    _buildDownloadButton(viewModel),
                    
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MedicalProfileViewModel viewModel) {
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
                  'Retour',
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
            'Profil Médical',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: viewModel.editProfile,
            child: Text(
              'Modifier',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(MedicalProfile profile) {
    return Column(
      children: [
        // Avatar with verified badge
        Stack(
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryRed,
                  width: 3,
                ),
                image: profile.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(profile.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: profile.avatarUrl == null
                  ? Center(
                      child: Text(
                        profile.fullName[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 40.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 32.w,
                height: 32.w,
                decoration: const BoxDecoration(
                  color: AppColors.primaryRed,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 18.sp,
                ),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16.h),
        
        // Name
        Text(
          profile.fullName,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        
        SizedBox(height: 8.h),
        
        // SOS ID
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            'ID: ${profile.sosId}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        
        SizedBox(height: 8.h),
        
        // Last Updated
        if (profile.lastUpdated != null)
          Text(
            'Dernière mise à jour: ${_formatDate(profile.lastUpdated!)}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
            ),
          ),
      ],
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideY(begin: 0.2, end: 0);
  }

  Widget _buildBloodTypeCard(MedicalProfile profile) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.primaryRed.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'GROUPE SANGUIN',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 2,
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Blood Type Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.bloodType.displayName[0],
                style: TextStyle(
                  fontSize: 64.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryRed,
                ),
              ),
              Column(
                children: [
                  Text(
                    profile.bloodType.displayName.substring(1),
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryRed,
                    ),
                  ),
                  Text(
                    'Rh+',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryRed.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // Universal Donor Badge
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
                  Icon(
                    Icons.favorite,
                    color: AppColors.primaryRed,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'DONNEUR UNIVERSEL',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 400.ms, delay: 100.ms)
      .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildVitalInfoSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Icon(
            Icons.monitor_heart,
            color: AppColors.primaryRed,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            'Informations Vitales',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
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
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: subtitleColor ?? AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppColors.textMuted,
            size: 24.sp,
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideX(begin: 0.1, end: 0);
  }

  Widget _buildEmergencyNotesCard(String notes) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
      ),
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
                child: Icon(
                  Icons.note_alt,
                  color: AppColors.primaryRed,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Text(
                "Notes d'Urgence",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            notes,
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
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideX(begin: 0.1, end: 0);
  }

  Widget _buildICEContactCard(ICEContact contact, MedicalProfileViewModel viewModel) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.contact_emergency,
              color: AppColors.primaryRed,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact ICE (Urgence)',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${contact.name} (${contact.relation})',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  contact.phoneNumber,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryRed,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: viewModel.callICEContact,
            child: Container(
              width: 48.w,
              height: 48.w,
              decoration: const BoxDecoration(
                color: AppColors.primaryRed,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideX(begin: 0.1, end: 0);
  }

  Widget _buildDownloadButton(MedicalProfileViewModel viewModel) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: viewModel.downloadPDF,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 18.h),
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
              Icon(
                Icons.download,
                color: AppColors.primaryRed,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Télécharger ma fiche (PDF)',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryRed,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 400.ms, delay: 200.ms);
  }

  String _formatDate(DateTime date) {
    final months = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  MedicalProfileViewModel viewModelBuilder(BuildContext context) => MedicalProfileViewModel();

  @override
  void onViewModelReady(MedicalProfileViewModel viewModel) => viewModel.initialize();
}
