import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sos1/app/app.locator.dart';
import 'package:sos1/services/sos_history_service.dart';
import 'package:sos1/models/sos_incident.dart';

class SOSHistoryViewModel extends BaseViewModel {
  final _historyService = locator<SOSHistoryService>();
  final _navigationService = locator<NavigationService>();

  List<SOSIncident> get incidents => _historyService.filteredIncidents;
  IncidentTab get selectedTab => _historyService.selectedTab;

  final List<IncidentTab> tabs = [
    IncidentTab.all,
    IncidentTab.medical,
    IncidentTab.security,
  ];

  Future<void> initialize() async {
    setBusy(true);
    // Service is already initialized via lazy singleton
    setBusy(false);
  }

  void setTab(IncidentTab tab) {
    _historyService.setSelectedTab(tab);
    notifyListeners();
  }

  Future<void> viewDetails(String incidentId) async {
    // Navigate to incident details
    print('View details for incident: $incidentId');
  }

  Future<void> reviewLog(String incidentId) async {
    await _historyService.reviewIncident(incidentId);
    notifyListeners();
  }

  void goBack() {
    _navigationService.back();
  }
}
