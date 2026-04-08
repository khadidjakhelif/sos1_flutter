import 'package:stacked/stacked.dart';
import '../models/medical_profile.dart';

class MedicalProfileService with ListenableServiceMixin {
  final ReactiveValue<MedicalProfile?> _profile = ReactiveValue<MedicalProfile?>(null);

  MedicalProfile? get profile => _profile.value;

  MedicalProfileService() {
    _initializeProfile();
  }

  void _initializeProfile() {
    _profile.value = MedicalProfile(
      id: '1',
      fullName: 'Ahmed Mansouri',
      sosId: 'SOS-213-99',
      avatarUrl: null,
      lastUpdated: DateTime(2023, 10, 12),
      bloodType: BloodType.oPositive,
      isUniversalDonor: true,
      chronicDiseases: ['Diabète Type 1', 'Hypertension artérielle'],
      allergies: ['Pénicilline', 'Arachides', 'Latex'],
      emergencyNotes: '"Porte un stimulateur cardiaque (Pacemaker). Contactez Dr. Bensalah au 021-XX-XX-XX en cas de crise cardiaque."',
      iceContact: ICEContact(
        name: 'Sonia Mansouri',
        relation: 'Épouse',
        phoneNumber: '0550 12 34 56',
      ),
    );
  }

  Future<void> updateProfile(MedicalProfile updatedProfile) async {
    _profile.value = updatedProfile.copyWith(
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> updateChronicDiseases(List<String> diseases) async {
    if (_profile.value != null) {
      _profile.value = _profile.value!.copyWith(
        chronicDiseases: diseases,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
    }
  }

  Future<void> updateAllergies(List<String> allergies) async {
    if (_profile.value != null) {
      _profile.value = _profile.value!.copyWith(
        allergies: allergies,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
    }
  }

  Future<void> updateEmergencyNotes(String notes) async {
    if (_profile.value != null) {
      _profile.value = _profile.value!.copyWith(
        emergencyNotes: notes,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
    }
  }

  Future<void> updateICEContact(ICEContact contact) async {
    if (_profile.value != null) {
      _profile.value = _profile.value!.copyWith(
        iceContact: contact,
        lastUpdated: DateTime.now(),
      );
      notifyListeners();
    }
  }

  Future<void> downloadPDF() async {
    // Implement PDF download functionality
    print('Downloading medical profile PDF...');
  }
}
