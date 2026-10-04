import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'emergency_contacts_viewmodel.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_language_provider.dart';
import '../../../models/medical_profile.dart';

class EmergencyContactsView extends StackedView<EmergencyContactsViewModel> {
  const EmergencyContactsView({super.key});

  @override
  Widget builder(BuildContext context, EmergencyContactsViewModel viewModel, Widget? child) {
    return Consumer<LanguageProvider>(
      builder: (context, lp, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(viewModel, lp),
                Expanded(
                  child: viewModel.isBusy
                      ? const Center(child: CircularProgressIndicator())
                      : _buildBody(context, viewModel, lp),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showContactBottomSheet(context, viewModel, lp),
            backgroundColor: AppColors.primaryRed,
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: Text(
              lp.translate('ice_add_contact'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(EmergencyContactsViewModel viewModel, LanguageProvider lp) {
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
                Text(lp.translate('back'),
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.white)),
              ],
            ),
          ),
          const Spacer(),
          Text(lp.translate('emergency_contacts'),
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700, color: Colors.white)),
          const Spacer(),
          SizedBox(width: 60.w),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, EmergencyContactsViewModel viewModel, LanguageProvider lp) {
    final contacts = viewModel.iceContacts;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 100.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoBanner(lp),
          SizedBox(height: 24.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(lp.translate('ice_contacts_section'),
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700,
                    color: AppColors.textMuted, letterSpacing: 2)),
          ),
          SizedBox(height: 16.h),
          if (contacts.isEmpty)
            _buildEmptyState(lp)
          else
            ...contacts.asMap().entries.map((e) => _buildContactCard(context, e.value, viewModel, lp, e.key)),
          if (viewModel.errorMessage != null)
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.primaryRed.withOpacity(0.3)),
                ),
                child: Text(viewModel.errorMessage!,
                    style: TextStyle(color: AppColors.primaryRed, fontSize: 13.sp)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(LanguageProvider lp) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF2A4A6A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24.w, height: 24.w,
            decoration: const BoxDecoration(color: Color(0xFF2196F3), shape: BoxShape.circle),
            child: Icon(Icons.info, color: Colors.white, size: 14.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(lp.translate('ice_info_banner'),
                style: TextStyle(fontSize: 13.sp, color: const Color(0xFF90CAF9), height: 1.5)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildEmptyState(LanguageProvider lp) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 48.h),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.people_outline, color: AppColors.textMuted, size: 64.sp),
            SizedBox(height: 16.h),
            Text(lp.translate('ice_no_contacts'),
                style: TextStyle(fontSize: 16.sp, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
            SizedBox(height: 8.h),
            Text(lp.translate('ice_no_contacts_subtitle'),
                style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted.withOpacity(0.7)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, ICEContact contact,
      EmergencyContactsViewModel viewModel, LanguageProvider lp, int index) {
    final colors = [
      const Color(0xFF9C27B0), const Color(0xFFFF9800),
      const Color(0xFF4CAF50), const Color(0xFF2196F3), const Color(0xFFE91E63),
    ];
    final avatarColor = colors[contact.name.length % colors.length];
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16.r)),
      child: Row(
        children: [
          Container(
            width: 52.w, height: 52.w,
            decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
            child: Center(
              child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name,
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                SizedBox(height: 2.h),
                Text(contact.relation,
                    style: TextStyle(fontSize: 12.sp, color: AppColors.primaryRed, fontWeight: FontWeight.w600)),
                SizedBox(height: 4.h),
                Row(children: [
                  Icon(Icons.phone, color: AppColors.textMuted, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text(contact.phoneNumber,
                      style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary)),
                ]),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () => _showContactBottomSheet(context, viewModel, lp, existing: contact, index: index),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8.r)),
                  child: Icon(Icons.edit_outlined, color: Colors.white70, size: 20.sp),
                ),
              ),
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: () => _confirmDelete(context, viewModel, lp, index),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.delete_outline, color: AppColors.primaryRed, size: 20.sp),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  void _confirmDelete(BuildContext context, EmergencyContactsViewModel viewModel,
      LanguageProvider lp, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(lp.translate('ice_delete_title'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(lp.translate('ice_delete_confirm'),
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(lp.translate('cancel'), style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(ctx); viewModel.deleteContact(index); },
            child: Text(lp.translate('delete'),
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showContactBottomSheet(BuildContext context, EmergencyContactsViewModel viewModel,
      LanguageProvider lp, {ICEContact? existing, int? index}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final relationCtrl = TextEditingController(text: existing?.relation ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phoneNumber ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          String? errorText;
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            padding: EdgeInsets.only(
              left: 24.w, right: 24.w, top: 24.h,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w, height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  existing == null ? lp.translate('ice_add_contact') : lp.translate('ice_edit_contact'),
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                SizedBox(height: 24.h),
                _sheetField(nameCtrl, lp.translate('ice_name'), Icons.person_outline),
                SizedBox(height: 16.h),
                _sheetField(relationCtrl, lp.translate('ice_relation'), Icons.people_outline),
                SizedBox(height: 16.h),
                _sheetField(phoneCtrl, lp.translate('ice_phone'), Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
                if (errorText != null) ...[
                  SizedBox(height: 12.h),
                  Text(errorText!, style: TextStyle(color: AppColors.primaryRed, fontSize: 13.sp)),
                ],
                SizedBox(height: 28.h),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(child: Text(lp.translate('cancel'),
                              style: TextStyle(color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600, fontSize: 15.sp))),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final name = nameCtrl.text.trim();
                          final relation = relationCtrl.text.trim();
                          final phone = phoneCtrl.text.trim();
                          if (name.isEmpty || phone.isEmpty) {
                            setSheetState(() => errorText = lp.translate('ice_fields_required'));
                            return;
                          }
                          final contact = ICEContact(name: name, relation: relation, phoneNumber: phone);
                          Navigator.pop(ctx);
                          if (existing == null) {
                            await viewModel.addContact(contact);
                          } else {
                            await viewModel.updateContact(index!, contact);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(child: Text(lp.translate('save'),
                              style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w700, fontSize: 15.sp))),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.primaryRed, width: 1.5),
        ),
      ),
    );
  }

  @override
  EmergencyContactsViewModel viewModelBuilder(BuildContext context) => EmergencyContactsViewModel();

  @override
  void onViewModelReady(EmergencyContactsViewModel viewModel) => viewModel.initialize();
}
