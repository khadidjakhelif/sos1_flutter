import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sos1/app/app.locator.dart';
import 'package:sos1/services/medical_profile_service.dart';
import 'package:sos1/models/medical_profile.dart';
import 'package:sos1/utils/app_language_provider.dart';
import '../../../app/app.router.dart';
import '../../../services/language_service.dart';
import 'package:provider/provider.dart';

class MedicalProfileViewModel extends BaseViewModel {
  final _medicalProfileService = locator<MedicalProfileService>();
  final _navigationService = locator<NavigationService>();
  final LanguageService lp = locator<LanguageService>();

  MedicalProfile? get profile => _medicalProfileService.profile;

  Future<void> initialize() async {
    setBusy(true);

    _medicalProfileService.addListener(() {
      notifyListeners();
    });

    setBusy(false);
  }

  Future<void> clearProfile(BuildContext context) async {
    final lp = Provider.of<LanguageProvider>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          lp.translate('clear_profile_title'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          lp.translate('clear_profile_message'),
          style: const TextStyle(color: Colors.grey, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              lp.translate('cancel'),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              lp.translate('delete'),
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _medicalProfileService.clearProfile();
    }
  }

  Future<void> editProfile() async {
    _navigationService.navigateTo(Routes.editMedicalProfileView);
  }

  void goBack() {
    _navigationService.back();
  }

  void callICEContact() {
    if (profile?.iceContact != null) {
      print('Calling ICE contact: ${profile!.iceContact!.phoneNumber}');
    }
  }
}
