import 'package:hive_flutter/hive_flutter.dart';
import 'package:stacked/stacked.dart';
import '../models/medical_profile.dart';

class MedicalProfileService with ListenableServiceMixin {
  static const _boxName = 'medicalProfile';
  static const _profileKey = 'profile';

  final ReactiveValue<MedicalProfile?> _profile = ReactiveValue<MedicalProfile?>(null);
  MedicalProfile? get profile => _profile.value;

  // Called once from setupLocator after the box is opened
  Future<void> initialize() async {
    final box = Hive.box<MedicalProfile>(_boxName);
    final saved = box.get(_profileKey);

    if (saved != null) {
      // Existing user — load saved data
      _profile.value = saved;
    }
    // If null → profile stays null, UI should prompt user to fill in their info
    notifyListeners();
  }


  Future<void> updateProfile(MedicalProfile updatedProfile) async {
    await _saveAndSet(updatedProfile.copyWith(lastUpdated: DateTime.now()));
  }

  Future<void> updateChronicDiseases(List<String> diseases) async {
    if (_profile.value == null) return;
    await _saveAndSet(_profile.value!.copyWith(
      chronicDiseases: diseases,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> updateAllergies(List<String> allergies) async {
    if (_profile.value == null) return;
    await _saveAndSet(_profile.value!.copyWith(
      allergies: allergies,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> updateEmergencyNotes(String notes) async {
    if (_profile.value == null) return;
    await _saveAndSet(_profile.value!.copyWith(
      emergencyNotes: notes,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> updateICEContact(ICEContact contact) async {
    if (_profile.value == null) return;
    await _saveAndSet(_profile.value!.copyWith(
      iceContact: contact,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> clearProfile() async {
    final box = Hive.box<MedicalProfile>(_boxName);
    await box.delete(_profileKey);
    _profile.value = null;
    notifyListeners();
  }


  Future<void> _saveAndSet(MedicalProfile updated) async {
    final box = Hive.box<MedicalProfile>(_boxName);
    await box.put(_profileKey, updated);
    _profile.value = updated;
    notifyListeners();
  }
}