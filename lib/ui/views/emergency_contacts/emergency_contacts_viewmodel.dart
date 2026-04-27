import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sos1/app/app.locator.dart';
import 'package:sos1/services/contacts_service.dart';
import 'package:sos1/models/emergency_contact.dart';
import 'package:sos1/services/emergency_actions_service.dart';

class EmergencyContactsViewModel extends BaseViewModel {
  final _contactsService = locator<ContactsService>();
  final _navigationService = locator<NavigationService>();
  final _emergencyActions = locator<EmergencyActionsService>();

  List<PublicService> get publicServices => _contactsService.publicServices;
  List<EmergencyContact> get personalContacts => _contactsService.personalContacts;

  Future<void> initialize() async {
    setBusy(true);
    // Services are already initialized via lazy singleton
    setBusy(false);
  }

  Future<void> callPublicService(String serviceId) async {
    await _contactsService.callPublicService(serviceId);
  }

  Future<void> callContact(String contactId) async {
    await _contactsService.callContact(contactId);
  }

  Future<void> toggleSmsAlert(String contactId, bool value) async {
    await _contactsService.updateContactToggles(contactId, smsAlert: value);
    notifyListeners();
  }

  Future<void> toggleAutoCall(String contactId, bool value) async {
    await _contactsService.updateContactToggles(contactId, autoCall: value);
    notifyListeners();
  }

  Future<void> addContact() async {
    // Navigate to add contact screen or show dialog
    print('Add new contact');
  }

  Future<void> deleteContact(String contactId) async {
    await _contactsService.removePersonalContact(contactId);
    notifyListeners();
  }

  Future<void> triggerSOS() async {
    // Send SMS to all contacts + auto-call first contact
    await _emergencyActions.triggerFullSOS(
      emergencyType: 'SOS Général',
      customMessage: 'Alerte SOS déclenchée manuellement.',
    );
  }

  void goBack() {
    _navigationService.back();
  }
}
