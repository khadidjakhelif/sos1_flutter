import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sos1/app/app.locator.dart';
import 'package:sos1/services/medical_profile_service.dart';
import 'package:sos1/models/medical_profile.dart';

class EditProfileViewModel extends BaseViewModel {
  final _medicalProfileService = locator<MedicalProfileService>();
  final _navigationService = locator<NavigationService>();

  // ── Form controllers ───────────────────────────────────────────────────────
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emergencyNotesController = TextEditingController();
  final TextEditingController iceNameController = TextEditingController();
  final TextEditingController iceRelationController = TextEditingController();
  final TextEditingController icePhoneController = TextEditingController();

  // ── Editable state ─────────────────────────────────────────────────────────
  BloodType _selectedBloodType = BloodType.oPositive;
  bool _isUniversalDonor = false;
  List<String> _chronicDiseases = [];
  List<String> _allergies = [];

  BloodType get selectedBloodType => _selectedBloodType;
  bool get isUniversalDonor => _isUniversalDonor;
  List<String> get chronicDiseases => List.unmodifiable(_chronicDiseases);
  List<String> get allergies => List.unmodifiable(_allergies);

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    setBusy(true);
    final profile = _medicalProfileService.profile;
    if (profile != null) {
      fullNameController.text = profile.fullName;
      emergencyNotesController.text = profile.emergencyNotes;
      iceNameController.text = profile.iceContact?.name ?? '';
      iceRelationController.text = profile.iceContact?.relation ?? '';
      icePhoneController.text = profile.iceContact?.phoneNumber ?? '';
      _selectedBloodType = profile.bloodType;
      _isUniversalDonor = profile.isUniversalDonor;
      _chronicDiseases = List.from(profile.chronicDiseases);
      _allergies = List.from(profile.allergies);
    }
    setBusy(false);
    notifyListeners();
  }

  // ── Blood type ─────────────────────────────────────────────────────────────
  void setBloodType(BloodType type) {
    _selectedBloodType = type;
    notifyListeners();
  }

  void toggleUniversalDonor(bool value) {
    _isUniversalDonor = value;
    notifyListeners();
  }

  // ── Chronic diseases ───────────────────────────────────────────────────────
  void addChronicDisease(String disease) {
    final trimmed = disease.trim();
    if (trimmed.isNotEmpty && !_chronicDiseases.contains(trimmed)) {
      _chronicDiseases.add(trimmed);
      notifyListeners();
    }
  }

  void removeChronicDisease(int index) {
    _chronicDiseases.removeAt(index);
    notifyListeners();
  }

  // ── Allergies ──────────────────────────────────────────────────────────────
  void addAllergy(String allergy) {
    final trimmed = allergy.trim();
    if (trimmed.isNotEmpty && !_allergies.contains(trimmed)) {
      _allergies.add(trimmed);
      notifyListeners();
    }
  }

  void removeAllergy(int index) {
    _allergies.removeAt(index);
    notifyListeners();
  }

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> saveProfile() async {
    setBusy(true);

    final existing = _medicalProfileService.profile;

    final iceContact = (iceNameController.text.trim().isNotEmpty ||
        icePhoneController.text.trim().isNotEmpty)
        ? ICEContact(
      name: iceNameController.text.trim(),
      relation: iceRelationController.text.trim(),
      phoneNumber: icePhoneController.text.trim(),
    )
        : null;

    final updated = MedicalProfile(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: fullNameController.text.trim(),
      sosId: existing?.sosId ??
          'SOS-213-${DateTime.now().millisecondsSinceEpoch % 99999}',
      avatarUrl: existing?.avatarUrl,
      lastUpdated: DateTime.now(),
      bloodType: _selectedBloodType,
      isUniversalDonor: _isUniversalDonor,
      chronicDiseases: List.from(_chronicDiseases),
      allergies: List.from(_allergies),
      emergencyNotes: emergencyNotesController.text.trim(),
      iceContact: iceContact,
    );

    await _medicalProfileService.updateProfile(updated);
    setBusy(false);
    _navigationService.back();
  }

  void goBack() => _navigationService.back();

  // ── Show add-item dialog helper (called from view) ─────────────────────────
  // Returns the entered text or null if cancelled
  Future<String?> showAddItemDialog(
      BuildContext context, {
        required String title,
        required String hint,
      }) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE53935)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Ajouter',
                style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emergencyNotesController.dispose();
    iceNameController.dispose();
    iceRelationController.dispose();
    icePhoneController.dispose();
    super.dispose();
  }
}