import 'package:stacked/stacked.dart';
import '../models/emergency_contact.dart';
import 'package:sos1/app/app.locator.dart';
import 'emergency_actions_service.dart';

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
    // Default emergency contact — user's own number
    _personalContacts.value = [
      EmergencyContact(
        id: '1',
        name: 'Khadidja',
        phoneNumber: '0782421992',
        relation: 'Contact principal',
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

  /// Call a public service (real number — Police, SAMU, etc.)
  Future<void> callPublicService(String serviceId) async {
    final service = _publicServices.value.firstWhere((s) => s.id == serviceId);
    final actions = locator<EmergencyActionsService>();
    await actions.callNumber(service.shortNumber);
  }

  /// Call a personal emergency contact (real number)
  Future<void> callContact(String contactId) async {
    final contact = _personalContacts.value.firstWhere((c) => c.id == contactId);
    final actions = locator<EmergencyActionsService>();
    await actions.callNumber(contact.phoneNumber);
  }
}

