import 'package:stacked/stacked.dart';
import '../models/sos_incident.dart';

class SOSHistoryService with ListenableServiceMixin {
  final ReactiveValue<List<SOSIncident>> _incidents = ReactiveValue<List<SOSIncident>>([]);
  final ReactiveValue<IncidentTab> _selectedTab = ReactiveValue<IncidentTab>(IncidentTab.all);

  List<SOSIncident> get incidents => _incidents.value;
  List<SOSIncident> get filteredIncidents {
    switch (_selectedTab.value) {
      case IncidentTab.all:
        return _incidents.value;
      case IncidentTab.medical:
        return _incidents.value.where((i) => i.type == IncidentType.medical || i.type == IncidentType.fire).toList();
      case IncidentTab.security:
        return _incidents.value.where((i) => i.type == IncidentType.security).toList();
    }
  }

  IncidentTab get selectedTab => _selectedTab.value;

  SOSHistoryService() {
    _initializeIncidents();
  }

  void _initializeIncidents() {
    _incidents.value = [
      SOSIncident(
        id: '1',
        title: 'Medical Emergency',
        type: IncidentType.medical,
        timestamp: DateTime(2023, 10, 12, 14, 30),
        location: "Sidi M'Hamed, Algiers",
        mapImageUrl: 'map_medical_1',
        latitude: 36.7538,
        longitude: 3.0588,
        status: 'completed',
        details: 'Emergency medical assistance requested',
      ),
      SOSIncident(
        id: '2',
        title: 'Security Alert',
        type: IncidentType.security,
        timestamp: DateTime(2023, 10, 5, 9, 15),
        location: 'Bab Ezzouar, Algiers',
        mapImageUrl: 'map_security_1',
        latitude: 36.7167,
        longitude: 3.1833,
        status: 'reviewed',
        details: 'Security concern reported',
      ),
      SOSIncident(
        id: '3',
        title: 'Cardiac Distress',
        type: IncidentType.medical,
        timestamp: DateTime(2023, 9, 28, 22, 45),
        location: 'Zeralda, Algiers',
        mapImageUrl: 'map_cardiac_1',
        latitude: 36.7167,
        longitude: 2.8500,
        status: 'reviewed',
        details: 'Cardiac emergency assistance',
      ),
    ];
  }

  void setSelectedTab(IncidentTab tab) {
    _selectedTab.value = tab;
    notifyListeners();
  }

  Future<void> addIncident(SOSIncident incident) async {
    _incidents.value = [incident, ..._incidents.value];
    notifyListeners();
  }

  Future<void> reviewIncident(String id) async {
    _incidents.value = _incidents.value.map((incident) {
      if (incident.id == id) {
        return SOSIncident(
          id: incident.id,
          title: incident.title,
          type: incident.type,
          timestamp: incident.timestamp,
          location: incident.location,
          mapImageUrl: incident.mapImageUrl,
          latitude: incident.latitude,
          longitude: incident.longitude,
          status: 'reviewed',
          details: incident.details,
        );
      }
      return incident;
    }).toList();
    notifyListeners();
  }

  SOSIncident? getIncidentById(String id) {
    try {
      return _incidents.value.firstWhere((i) => i.id == id);
    } catch (e) {
      return null;
    }
  }
}
