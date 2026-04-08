import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'emergency_contacts_viewmodel.dart';
import '../../../utils/app_colors.dart';
import '../../../models/emergency_contact.dart';

class EmergencyContactsView extends StackedView<EmergencyContactsViewModel> {
  const EmergencyContactsView({super.key});

  @override
  Widget builder(
    BuildContext context,
    EmergencyContactsViewModel viewModel,
    Widget? child,
  ) {
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
                    // Public Services Section
                    _buildSectionTitle('SERVICES PUBLICS'),
                    SizedBox(height: 16.h),
                    ...viewModel.publicServices.map((service) => _buildPublicServiceCard(service, viewModel)),
                    
                    SizedBox(height: 32.h),
                    
                    // Personal Contacts Section
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('CONTACTS PERSONNELS'),
                          _buildAddButton(viewModel),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ...viewModel.personalContacts.map((contact) => _buildPersonalContactCard(contact, viewModel)),
                    
                    SizedBox(height: 24.h),
                    
                    // Info Card
                    _buildInfoCard(),
                    
                    SizedBox(height: 24.h),
                    
                    // SOS Button
                    _buildSOSButton(viewModel),
                    
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

  Widget _buildHeader(EmergencyContactsViewModel viewModel) {
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
            "Contacts\nd'Urgence",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const Spacer(),
          SizedBox(width: 60.w),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Text(
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

  Widget _buildAddButton(EmergencyContactsViewModel viewModel) {
    return GestureDetector(
      onTap: viewModel.addContact,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle,
              color: AppColors.primaryRed,
              size: 18.sp,
            ),
            SizedBox(width: 6.w),
            Text(
              'AJOUTER',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicServiceCard(PublicService service, EmergencyContactsViewModel viewModel) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: _getServiceColor(service.type).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              _getServiceIcon(service.type),
              color: _getServiceColor(service.type),
              size: 28.sp,
            ),
          ),
          SizedBox(width: 16.w),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${service.shortNumber} / ${service.fullNumber}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryRed,
                  ),
                ),
              ],
            ),
          ),
          
          // Call Button
          GestureDetector(
            onTap: () => viewModel.callPublicService(service.id),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.primaryRed,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'APPEL',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideX(begin: -0.1, end: 0);
  }

  Widget _buildPersonalContactCard(EmergencyContact contact, EmergencyContactsViewModel viewModel) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              // Avatar
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: _getAvatarColor(contact.name),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    contact.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      contact.phoneNumber,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Delete Button
              GestureDetector(
                onTap: () => viewModel.deleteContact(contact.id),
                child: Icon(
                  Icons.delete_outline,
                  color: AppColors.textMuted,
                  size: 24.sp,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // Toggles Row
          Row(
            children: [
              // SMS Alert Toggle
              Expanded(
                child: _buildToggle(
                  'ALERT SMS',
                  contact.smsAlertEnabled ? 'ACTIF' : 'OFF',
                  contact.smsAlertEnabled,
                  (value) => viewModel.toggleSmsAlert(contact.id, value),
                ),
              ),
              SizedBox(width: 12.w),
              
              // Auto Call Toggle
              Expanded(
                child: _buildToggle(
                  'APPEL AUTO',
                  contact.autoCallEnabled ? 'ACTIF' : 'OFF',
                  contact.autoCallEnabled,
                  (value) => viewModel.toggleAutoCall(contact.id, value),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildToggle(String label, String status, bool value, Function(bool) onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: value ? AppColors.primaryRed : AppColors.textMuted,
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryRed,
            activeTrackColor: AppColors.primaryRed.withOpacity(0.3),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF2A4A6A),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: const BoxDecoration(
              color: Color(0xFF2196F3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info,
              color: Colors.white,
              size: 14.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              "En cas d'urgence majeure, vos contacts recevront votre position GPS exacte par SMS et seront appelés selon vos réglages.",
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF90CAF9),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildSOSButton(EmergencyContactsViewModel viewModel) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: viewModel.triggerSOS,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SOS',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'SIGNALEMENT RAPIDE',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 400.ms, delay: 300.ms)
      .then()
      .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.1));
  }

  Color _getServiceColor(ServiceType type) {
    switch (type) {
      case ServiceType.police:
        return const Color(0xFF2196F3);
      case ServiceType.civilProtection:
        return const Color(0xFFFF9800);
      case ServiceType.medical:
        return const Color(0xFF4CAF50);
      case ServiceType.fire:
        return const Color(0xFFF44336);
    }
  }

  IconData _getServiceIcon(ServiceType type) {
    switch (type) {
      case ServiceType.police:
        return Icons.shield;
      case ServiceType.civilProtection:
        return Icons.local_fire_department;
      case ServiceType.medical:
        return Icons.medical_services;
      case ServiceType.fire:
        return Icons.fire_extinguisher;
    }
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFE91E63),
    ];
    return colors[name.length % colors.length];
  }

  @override
  EmergencyContactsViewModel viewModelBuilder(BuildContext context) => EmergencyContactsViewModel();

  @override
  void onViewModelReady(EmergencyContactsViewModel viewModel) => viewModel.initialize();
}
