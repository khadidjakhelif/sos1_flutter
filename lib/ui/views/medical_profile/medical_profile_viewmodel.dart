import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sos1/app/app.locator.dart';
import 'package:sos1/services/medical_profile_service.dart';
import 'package:sos1/models/medical_profile.dart';

class MedicalProfileViewModel extends BaseViewModel {
  final _medicalProfileService = locator<MedicalProfileService>();
  final _navigationService = locator<NavigationService>();

  MedicalProfile? get profile => _medicalProfileService.profile;

  Future<void> initialize() async {
    setBusy(true);
    // Service is already initialized via lazy singleton
    setBusy(false);
  }

  Future<void> downloadPDF() async {
    await _medicalProfileService.downloadPDF();
  }

  Future<void> editProfile() async {
    // Navigate to edit profile screen
    print('Edit profile');
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
