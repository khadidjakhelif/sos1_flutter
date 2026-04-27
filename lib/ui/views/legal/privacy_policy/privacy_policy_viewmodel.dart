import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../../app/app.locator.dart';

class PrivacyPolicyViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  void goBack() => _navigationService.back();

  void openEmail() {
    // Add email intent
    print('Opening support@sosalgerie.app');
  }
}