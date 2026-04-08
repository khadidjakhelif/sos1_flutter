import 'package:stacked/stacked.dart';
import '../models/emergency_contact.dart';

class ContactsService with ListenableServiceMixin {
  final ReactiveValue<List<PublicService>> _publicServices = ReactiveValue<List<PublicService>>([]);
  final ReactiveValue<List<EmergencyContact>> _personalContacts = ReactiveValue<List<EmergencyContact>>([]);

  List<PublicService> get publicServices => _publicServices.value;
  List<EmergencyContact> get personalContacts => _personalContacts.value;

  ContactsService() {
    _initializePublicServices();
    _initializePersonalContacts();
  }

  void _initializePublicServices() {
    _publicServices.value = [
      PublicService(
        id: 'police',
        name: 'Police',
        shortNumber: '17',
        fullNumber: '1548',
        type: ServiceType.police,
        iconAsset: 'shield',
      ),
      PublicService(
        id: 'civil_protection',
        name: 'Protection Civile',
        shortNumber: '14',
        fullNumber: '1021',
        type: ServiceType.civilProtection,
        iconAsset: 'fire',
      ),
      PublicService(
        id: 'samu',
        name: 'SAMU',
        shortNumber: '115',
        fullNumber: '3030',
        type: ServiceType.medical,
        iconAsset: 'medical',
      ),
    ];
  }

  void _initializePersonalContacts() {
    _personalContacts.value = [
      EmergencyContact(
        id: '1',
        name: 'Khadidja (Maman)',
        phoneNumber: '+213 555 12 34 56',
        relation: 'Mère',
        smsAlertEnabled: true,
        autoCallEnabled: false,
      ),
      EmergencyContact(
        id: '2',
        name: 'Ahmed (Frère)',
        phoneNumber: '+213 661 98 76 54',
        relation: 'Frère',
        smsAlertEnabled: true,
        autoCallEnabled: true,
      ),
    ];
  }

  Future<void> addPersonalContact(EmergencyContact contact) async {
    _personalContacts.value = [..._personalContacts.value, contact];
    notifyListeners();
  }

  Future<void> removePersonalContact(String id) async {
    _personalContacts.value = _personalContacts.value.where((c) => c.id != id).toList();
    notifyListeners();
  }

  Future<void> updateContactToggles(String id, {bool? smsAlert, bool? autoCall}) async {
    _personalContacts.value = _personalContacts.value.map((contact) {
      if (contact.id == id) {
        return contact.copyWith(
          smsAlertEnabled: smsAlert ?? contact.smsAlertEnabled,
          autoCallEnabled: autoCall ?? contact.autoCallEnabled,
        );
      }
      return contact;
    }).toList();
    notifyListeners();
  }

  Future<void> callPublicService(String serviceId) async {
    // Implement phone call functionality
    final service = _publicServices.value.firstWhere((s) => s.id == serviceId);
    print('Calling ${service.name} at ${service.shortNumber}');
  }

  Future<void> callContact(String contactId) async {
    // Implement phone call functionality
    final contact = _personalContacts.value.firstWhere((c) => c.id == contactId);
    print('Calling ${contact.name} at ${contact.phoneNumber}');
  }
}
