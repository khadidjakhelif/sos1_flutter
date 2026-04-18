import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sos1/app/app.locator.dart';
import 'package:sos1/app/app.router.dart';

class SettingsViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  String get appVersion => 'v2.4.0';
  String get emergencyNumber => '14 / 17';

  Future<void> initialize() async {
    setBusy(true);
    // Initialize settings
    setBusy(false);
  }

  void navigateToMedicalProfile() {
    _navigationService.navigateTo(Routes.medicalProfileView);
  }

  void navigateToPrivacyPolicy() {
    _navigationService.navigateTo(Routes.privacyPolicyView);
  }

  void navigateToTermsOfUse() {
    _navigationService.navigateTo(Routes.termsOfUseView);
  }

  void navigateToEmergencyContacts() {
    _navigationService.navigateTo(Routes.emergencyContactsView);
  }

  void navigateToLanguageSelection() {
    _navigationService.navigateTo(Routes.languageSelectionView);
  }

  void navigateToLocationSharing() {
    // Navigate to location sharing settings
    print('Navigate to location sharing');
  }

  void navigateToSOSHistory() {
    _navigationService.navigateTo(Routes.sOSHistoryView);
  }

  Future<void> logout() async {
    // Implement logout functionality
    print('Logout');
    _navigationService.clearStackAndShow('/');
  }

  void goBack() {
    _navigationService.back();
  }
}
