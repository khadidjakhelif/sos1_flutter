import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/app.locator.dart';

class TermsOfUseViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  // Emergency numbers - easy to call
  final Map<String, String> emergencyNumbers = {
    'samu': 'tel:15',
    'police': 'tel:17',
    'pompiers': 'tel:14',
  };

  Future<void> callEmergency(String type) async {
    final url = emergencyNumbers[type];
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void goBack() => _navigationService.back();

}