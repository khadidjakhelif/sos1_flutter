import 'package:stacked/stacked.dart';
import 'package:hive/hive.dart';
import '../models/emergency_history.dart';
import '../app/app.locator.dart';
import 'api_service.dart';

enum IncidentTab { all, medical, security }

class SOSHistoryService with ListenableServiceMixin {
  final _apiService = locator<ApiService>();
  final ReactiveValue<List<EmergencyHistory>> _incidents =
      ReactiveValue<List<EmergencyHistory>>([]);
  final ReactiveValue<IncidentTab> _selectedTab =
      ReactiveValue<IncidentTab>(IncidentTab.all);

  List<EmergencyHistory> get incidents => _incidents.value;
  List<EmergencyHistory> get filteredIncidents {
    switch (_selectedTab.value) {
      case IncidentTab.all:
        return _incidents.value;
      case IncidentTab.medical:
        return _incidents.value
            .where((i) =>
                i.type.toLowerCase() == 'medical' ||
                i.type.toLowerCase() == 'fire')
            .toList();
      case IncidentTab.security:
        return _incidents.value
            .where((i) =>
                i.type.toLowerCase() == 'security' ||
                i.type.toLowerCase() == 'police')
            .toList();
    }
  }

  IncidentTab get selectedTab => _selectedTab.value;

  SOSHistoryService() {
    _initializeIncidents();
  }

  Future<void> addIncident(EmergencyHistory incident) async {
    var box = await Hive.openBox<EmergencyHistory>('emergencyHistoryBox');
    await box.put(incident.id, incident);
    _incidents.value = [incident, ..._incidents.value]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    notifyListeners();
  }

  Future<void> _initializeIncidents() async {
    // Load from Hive cache first
    var box = await Hive.openBox<EmergencyHistory>('emergencyHistoryBox');
    _incidents.value = box.values.toList().cast<EmergencyHistory>();

    // Sort by startedAt descending
    _incidents.value.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    notifyListeners();

    // Fetch from API
    try {
      final remoteData = await _apiService.getEmergencyHistory();
      final List<EmergencyHistory> newHistory =
          remoteData.map((e) => EmergencyHistory.fromJson(e)).toList();

      // Update cache
      await box.clear();
      await box.addAll(newHistory);

      _incidents.value = newHistory;
      // Sort again just in case
      _incidents.value.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      notifyListeners();
    } catch (e) {
      print('Failed to fetch emergency history: $e');
    }
  }

  void setSelectedTab(IncidentTab tab) {
    _selectedTab.value = tab;
    notifyListeners();
  }

  Future<void> reviewIncident(String id) async {
    // For now this does nothing as API holds truth
  }

  EmergencyHistory? getIncidentById(String id) {
    try {
      return _incidents.value.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }
}
