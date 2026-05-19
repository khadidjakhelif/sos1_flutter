import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sos1/app/app.locator.dart';
import 'package:sos1/app/app.router.dart';
import 'package:sos1/services/api_service.dart';

class SettingsViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _apiService = locator<ApiService>();

  String get appVersion => 'v1.0.0';
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
    setBusy(true);
    await _apiService.logout();
    setBusy(false);
    _navigationService.clearStackAndShow(Routes.loginView);
  }

  void goBack() {
    _navigationService.back();
  }
}
