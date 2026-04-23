import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stacked/stacked.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_language_provider.dart';
import '../../../models/medical_profile.dart';
import '../../../ui/views/edit_medical_profile/edit_medical_profile_viewmodel.dart';

class EditProfileView extends StackedView<EditProfileViewModel> {
  const EditProfileView({super.key});

  @override
  Widget builder(
      BuildContext context,
      EditProfileViewModel viewModel,
      Widget? child,
      ) {
    return Consumer<LanguageProvider>(
      builder: (context, lp, _) {
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

                        // Full Name
                        _buildSectionTitle(lp.translate('full_name'), Icons.person),
                        SizedBox(height: 12.h),
                        _buildTextField(
                          controller: viewModel.fullNameController,
                          hint: lp.translate('full_name_hint'),
                        ),

                        SizedBox(height: 28.h),

                        // Blood Type
                        _buildSectionTitle(lp.translate('blood_type'), Icons.water_drop),
                        SizedBox(height: 12.h),
                        _buildBloodTypeSelector(viewModel),

                        SizedBox(height: 16.h),

                        // Universal Donor Toggle
                        _buildToggleCard(
                          title: lp.translate('universal_donor'),
                          subtitle: lp.translate('universal_donor_hint'),
                          value: viewModel.isUniversalDonor,
                          onChanged: viewModel.toggleUniversalDonor,
                        ),

                        SizedBox(height: 28.h),

                        // Chronic Diseases
                        _buildSectionTitle(lp.translate('chronic_diseases'), Icons.monitor_heart),
                        SizedBox(height: 12.h),
                        _buildTagList(
                          context: context,
                          items: viewModel.chronicDiseases,
                          addLabel: lp.translate('add_disease'),
                          dialogTitle: lp.translate('add_disease'),
                          dialogHint: lp.translate('disease_hint'),
                          onAdd: viewModel.addChronicDisease,
                          onRemove: viewModel.removeChronicDisease,
                          viewModel: viewModel,
                        ),

                        SizedBox(height: 28.h),

                        // Allergies
                        _buildSectionTitle(lp.translate('allergies'), Icons.warning_amber),
                        SizedBox(height: 12.h),
                        _buildTagList(
                          context: context,
                          items: viewModel.allergies,
                          addLabel: lp.translate('add_allergy'),
                          dialogTitle: lp.translate('add_allergy'),
                          dialogHint: lp.translate('allergy_hint'),
                          onAdd: viewModel.addAllergy,
                          onRemove: viewModel.removeAllergy,
                          viewModel: viewModel,
                          tagColor: AppColors.primaryRed,
                        ),

                        SizedBox(height: 28.h),

                        // Emergency Notes
                        _buildSectionTitle(lp.translate('emergency_notes'), Icons.note_alt),
                        SizedBox(height: 12.h),
                        _buildTextField(
                          controller: viewModel.emergencyNotesController,
                          hint: lp.translate('emergency_notes_hint'),
                          maxLines: 4,
                        ),

                        SizedBox(height: 28.h),

                        // ICE Contact
                        _buildSectionTitle(lp.translate('ice_contact'), Icons.contact_emergency),
                        SizedBox(height: 12.h),
                        _buildICESection(viewModel, lp),

                        SizedBox(height: 40.h),

                        // Save Button
                        _buildSaveButton(viewModel, lp),

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

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(EditProfileViewModel viewModel, LanguageProvider lp) {
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
            lp.translate('edit_profile_title'),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Busy indicator while saving
          SizedBox(width: 60.w),
        ],
      ),
    );
  }

  // ── Section title ──────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryRed, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ── Text field ─────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primaryRed.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(fontSize: 15.sp, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14.sp, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  // ── Blood type selector ────────────────────────────────────────────────────

  Widget _buildBloodTypeSelector(EditProfileViewModel viewModel) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primaryRed.withOpacity(0.2)),
      ),
      child: Wrap(
        spacing: 10.w,
        runSpacing: 10.h,
        children: BloodType.values.map((type) {
          final isSelected = viewModel.selectedBloodType == type;
          return GestureDetector(
            onTap: () => viewModel.setBloodType(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryRed
                    : AppColors.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryRed
                      : AppColors.primaryRed.withOpacity(0.3),
                ),
              ),
              child: Text(
                type.displayName,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  // ── Toggle card ────────────────────────────────────────────────────────────

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
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
              color: AppColors.primaryRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.favorite, color: AppColors.primaryRed, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                SizedBox(height: 2.h),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12.sp, color: AppColors.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryRed,
          ),
        ],
      ),
    );
  }

  // ── Tag list (diseases / allergies) ───────────────────────────────────────

  Widget _buildTagList({
    required BuildContext context,
    required List<String> items,
    required String addLabel,
    required String dialogTitle,
    required String dialogHint,
    required Function(String) onAdd,
    required Function(int) onRemove,
    required EditProfileViewModel viewModel,
    Color tagColor = AppColors.primaryRed,
  }) {
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
          // Tags
          if (items.isNotEmpty)
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: items.asMap().entries.map((entry) {
                return Container(
                  padding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: tagColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border:
                    Border.all(color: tagColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.value,
                        style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500),
                      ),
                      SizedBox(width: 6.w),
                      GestureDetector(
                        onTap: () => onRemove(entry.key),
                        child: Icon(Icons.close,
                            size: 14.sp, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          if (items.isNotEmpty) SizedBox(height: 12.h),

          // Add button
          GestureDetector(
            onTap: () async {
              final result = await viewModel.showAddItemDialog(
                context,
                title: dialogTitle,
                hint: dialogHint,
              );
              if (result != null && result.trim().isNotEmpty) {
                onAdd(result);
              }
            },
            child: Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.add,
                      color: AppColors.primaryRed, size: 18.sp),
                ),
                SizedBox(width: 10.w),
                Text(
                  addLabel,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  // ── ICE Contact ────────────────────────────────────────────────────────────

  Widget _buildICESection(EditProfileViewModel viewModel, LanguageProvider lp) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primaryRed.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildInlineField(
            controller: viewModel.iceNameController,
            label: lp.translate('ice_name'),
            icon: Icons.person,
          ),
          SizedBox(height: 12.h),
          _buildInlineField(
            controller: viewModel.iceRelationController,
            label: lp.translate('ice_relation'),
            icon: Icons.people,
          ),
          SizedBox(height: 12.h),
          _buildInlineField(
            controller: viewModel.icePhoneController,
            label: lp.translate('ice_phone'),
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0);
  }

  Widget _buildInlineField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(fontSize: 14.sp, color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle:
              TextStyle(fontSize: 13.sp, color: AppColors.textMuted),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: AppColors.primaryRed.withOpacity(0.3)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryRed),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Save button ────────────────────────────────────────────────────────────

  Widget _buildSaveButton(
      EditProfileViewModel viewModel, LanguageProvider lp) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: viewModel.isBusy ? null : viewModel.saveProfile,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 18.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.redGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryRed.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: viewModel.isBusy
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.save, color: Colors.white, size: 20.sp),
                SizedBox(width: 10.w),
                Text(
                  lp.translate('save'),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  @override
  EditProfileViewModel viewModelBuilder(BuildContext context) =>
      EditProfileViewModel();

  @override
  void onViewModelReady(EditProfileViewModel viewModel) =>
      viewModel.initialize();
}